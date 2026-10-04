-- ====================================================
-- RLS POLICIES FIX
-- Run this in Supabase SQL Editor
-- ====================================================

-- ────────────────────────────────────────────────────
-- PRODUCTS TABLE
-- ────────────────────────────────────────────────────

-- Drop existing policies (safe - won't fail if not exists)
DROP POLICY IF EXISTS "products_select_active" ON public.products;
DROP POLICY IF EXISTS "products_select_admin" ON public.products;
DROP POLICY IF EXISTS "products_insert_admin" ON public.products;
DROP POLICY IF EXISTS "products_update_admin" ON public.products;
DROP POLICY IF EXISTS "products_delete_admin" ON public.products;

-- Make sure RLS is enabled
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Allow public (anon & authenticated customers/merchants) to SELECT active products (or products where is_active IS NULL)
CREATE POLICY "products_select_public"
  ON public.products
  FOR SELECT
  TO public
  USING (is_active = true OR is_active IS NULL);

-- Admin can SELECT ALL products (including inactive)
CREATE POLICY "products_select_admin"
  ON public.products
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- Admin can INSERT
CREATE POLICY "products_insert_admin"
  ON public.products
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- Admin can UPDATE
CREATE POLICY "products_update_admin"
  ON public.products
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Admin can DELETE
CREATE POLICY "products_delete_admin"
  ON public.products
  FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ────────────────────────────────────────────────────
-- ADVERTISEMENTS TABLE
-- ────────────────────────────────────────────────────

DROP POLICY IF EXISTS "ads_select_active" ON public.advertisements;
DROP POLICY IF EXISTS "ads_select_admin" ON public.advertisements;
DROP POLICY IF EXISTS "ads_insert_admin" ON public.advertisements;
DROP POLICY IF EXISTS "ads_update_admin" ON public.advertisements;
DROP POLICY IF EXISTS "ads_delete_admin" ON public.advertisements;

ALTER TABLE public.advertisements ENABLE ROW LEVEL SECURITY;

-- Authenticated users can SELECT active ads
CREATE POLICY "ads_select_active"
  ON public.advertisements
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Admin can SELECT ALL ads
CREATE POLICY "ads_select_admin"
  ON public.advertisements
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- Admin can INSERT
CREATE POLICY "ads_insert_admin"
  ON public.advertisements
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- Admin can UPDATE
CREATE POLICY "ads_update_admin"
  ON public.advertisements
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Admin can DELETE
CREATE POLICY "ads_delete_admin"
  ON public.advertisements
  FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ────────────────────────────────────────────────────
-- VERIFY: Check current policies
-- ────────────────────────────────────────────────────
SELECT schemaname, tablename, policyname, cmd, roles
FROM pg_policies
WHERE tablename IN ('products', 'advertisements')
ORDER BY tablename, policyname;
