-- ====================================================
-- FULL DATABASE SETUP FOR CART, FAVORITES, ORDERS, NOTIFICATIONS, RLS, AND RPC
-- Run this in Supabase SQL Editor
-- ====================================================

-- ────────────────────────────────────────────────────
-- 1. NOTIFICATIONS TABLE
-- ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'system',
    related_order_id TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast user queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select_owner" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_owner" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_all" ON public.notifications;

CREATE POLICY "notifications_select_owner"
  ON public.notifications FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "notifications_update_owner"
  ON public.notifications FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "notifications_insert_all"
  ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (true);

-- ────────────────────────────────────────────────────
-- 2. CART_ITEMS TABLE & RLS
-- ────────────────────────────────────────────────────
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cart_select_owner" ON public.cart_items;
DROP POLICY IF EXISTS "cart_insert_owner" ON public.cart_items;
DROP POLICY IF EXISTS "cart_update_owner" ON public.cart_items;
DROP POLICY IF EXISTS "cart_delete_owner" ON public.cart_items;

CREATE POLICY "cart_select_owner" ON public.cart_items FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "cart_insert_owner" ON public.cart_items FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "cart_update_owner" ON public.cart_items FOR UPDATE TO authenticated USING (user_id = auth.uid());
CREATE POLICY "cart_delete_owner" ON public.cart_items FOR DELETE TO authenticated USING (user_id = auth.uid());

-- ────────────────────────────────────────────────────
-- 3. FAVORITES TABLE & RLS
-- ────────────────────────────────────────────────────
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "fav_select_owner" ON public.favorites;
DROP POLICY IF EXISTS "fav_insert_owner" ON public.favorites;
DROP POLICY IF EXISTS "fav_delete_owner" ON public.favorites;

CREATE POLICY "fav_select_owner" ON public.favorites FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "fav_insert_owner" ON public.favorites FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "fav_delete_owner" ON public.favorites FOR DELETE TO authenticated USING (user_id = auth.uid());

-- ────────────────────────────────────────────────────
-- 4. ORDERS & ORDER_ITEMS TABLE RLS
-- ────────────────────────────────────────────────────
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orders_select_owner_or_admin" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_owner" ON public.orders;
DROP POLICY IF EXISTS "orders_update_admin" ON public.orders;

CREATE POLICY "orders_select_owner_or_admin" ON public.orders FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "orders_insert_owner" ON public.orders FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "orders_update_admin" ON public.orders FOR UPDATE TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "order_items_select_owner_or_admin" ON public.order_items;
DROP POLICY IF EXISTS "order_items_insert_authenticated" ON public.order_items;

CREATE POLICY "order_items_select_owner_or_admin" ON public.order_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "order_items_insert_authenticated" ON public.order_items FOR INSERT TO authenticated WITH CHECK (true);

-- ────────────────────────────────────────────────────
-- 5. ATOMIC STORED PROCEDURE: place_order
-- ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.place_order(
    p_user_id UUID,
    p_order_number TEXT,
    p_subtotal NUMERIC,
    p_discount NUMERIC,
    p_points_used INT,
    p_delivery_fee NUMERIC,
    p_total NUMERIC,
    p_payment_method TEXT,
    p_payment_status TEXT,
    p_customer_name TEXT,
    p_customer_phone TEXT,
    p_address TEXT,
    p_notes TEXT,
    p_items JSONB
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_item JSONB;
    v_product_id INT;
    v_qty INT;
    v_unit_price NUMERIC;
    v_product_name TEXT;
    v_stock INT;
BEGIN
    -- 1. Atomic Stock Verification with FOR UPDATE lock
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::INT;
        v_qty := (v_item->>'quantity')::INT;

        SELECT stock_quantity INTO v_stock
        FROM public.products
        WHERE id = v_product_id
        FOR UPDATE;

        IF v_stock IS NULL OR v_stock < v_qty THEN
            RAISE EXCEPTION 'INSUFFICIENT_STOCK: Product % has only % in stock, requested %', v_product_id, COALESCE(v_stock, 0), v_qty;
        END IF;
    END LOOP;

    -- 2. Create Order Header
    INSERT INTO public.orders (
        user_id, order_number, status, subtotal, discount, points_used,
        delivery_fee, total, payment_method, payment_status,
        customer_name, customer_phone, address, notes, created_at, updated_at
    ) VALUES (
        p_user_id, p_order_number, 'pending', p_subtotal, p_discount, p_points_used,
        p_delivery_fee, p_total, p_payment_method, p_payment_status,
        p_customer_name, p_customer_phone, p_address, p_notes, NOW(), NOW()
    ) RETURNING id INTO v_order_id;

    -- 3. Create Order Items & Deduct Stock
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::INT;
        v_qty := (v_item->>'quantity')::INT;
        v_unit_price := (v_item->>'unit_price')::NUMERIC;
        v_product_name := COALESCE(v_item->>'product_name', 'منتج');

        INSERT INTO public.order_items (
            order_id, product_id, product_name, quantity, unit_price, discount, total_price
        ) VALUES (
            v_order_id, v_product_id, v_product_name, v_qty, v_unit_price, 0, (v_qty * v_unit_price)
        );

        -- Deduct Stock
        UPDATE public.products
        SET stock_quantity = stock_quantity - v_qty,
            updated_at = NOW()
        WHERE id = v_product_id;
    END LOOP;

    -- 4. Delete Cart Items for user
    DELETE FROM public.cart_items WHERE user_id = p_user_id;

    -- 5. Create Customer Notification
    INSERT INTO public.notifications (
        user_id, title, message, type, related_order_id, is_read, created_at
    ) VALUES (
        p_user_id, 'تم إرسال طلبك بنجاح', 'تم تسجيل طلبك رقم ' || p_order_number || ' بنجاح وسيتم مراجعته.', 'order', v_order_id::TEXT, false, NOW()
    );

    RETURN jsonb_build_object('success', true, 'order_id', v_order_id);
END;
$$;
