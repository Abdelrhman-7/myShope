import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_providers.dart';
import '../controller/home_controller.dart';

class AdsSection extends ConsumerWidget {
  final double horizontalPadding;
  
  const AdsSection({super.key, required this.horizontalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(homeAdsProvider);
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    return adsAsync.when(
      data: (ads) {
        if (ads.isEmpty) return const SizedBox.shrink();
        
        return SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: ads.length,
            controller: PageController(viewportFraction: 0.9),
            itemBuilder: (context, index) {
              final ad = ads[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () async {
                    if (ad.targetUrl != null && ad.targetUrl!.isNotEmpty) {
                      final uri = Uri.parse(ad.targetUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: ad.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.grey200,
                              child: const Center(child: CircularProgressIndicator.adaptive()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.grey300,
                              child: const Icon(Icons.image_not_supported, color: AppColors.grey500),
                            ),
                          )
                        else
                          Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Center(
                              child: Icon(Icons.campaign, size: 64, color: AppColors.primary),
                            ),
                          ),
                          
                        // Overlay Gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        
                        // Text Content
                        Positioned(
                          bottom: AppSpacing.md,
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? ad.titleAr : ad.titleEn,
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((isArabic ? ad.descriptionAr : ad.descriptionEn) != null && 
                                  (isArabic ? ad.descriptionAr : ad.descriptionEn)!.isNotEmpty)
                                ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    isArabic ? ad.descriptionAr! : ad.descriptionEn!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
