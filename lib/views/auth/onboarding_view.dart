import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/prefs/app_prefs.dart';
import 'package:tabala/views/auth/welcome_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _controller = PageController();

  int currentIndex = 0;

  final List<Map<String, String>> pages = [
    {
      "step": "onboard_step1".tr(),
      "title": "onboard_title1".tr(),
      "description": "onboard_desc1".tr(),
    },
    {
      "step": "onboard_step2".tr(),
      "title": "onboard_title2".tr(),
      "description": "onboard_desc2".tr(),
    },
    {
      "step": "onboard_step3".tr(),
      "title": "onboard_title3".tr(),
      "description": "onboard_desc3".tr(),
    },
  ];

  void nextPage() {
    if (currentIndex == pages.length - 1) {
      AppPrefs.setOnboardingSeen();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WelcomeView()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip() {
    AppPrefs.setOnboardingSeen();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WelcomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFBF8EF),
      body: SafeArea(
        child: PageView.builder(
          controller: _controller,
          itemCount: pages.length,
          onPageChanged: (value) {
            setState(() {
              currentIndex = value;
            });
          },
          itemBuilder: (context, index) {
            return SingleChildScrollView( // (from previous fix)
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: skip,
                        child: Text("skip".tr(), style: AppStyles.medium16Yellow),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primarycolor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Icon(
                            index == 0
                                ? Icons.calendar_month_outlined
                                : index == 1
                                ? Icons.hub_outlined
                                : Icons.check_circle_outline,
                            color: AppColors.yellowcolor,
                            size: 42,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        pages[index]["step"]!,
                        style: AppStyles.bold16Yellow,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      pages[index]["title"]!,
                      textAlign: TextAlign.center,
                      style: AppStyles.bold32Primary,
                    ),

                    const SizedBox(height: 18),

                    Text(
                      pages[index]["description"]!,
                      textAlign: TextAlign.center,
                      style: AppStyles.regular14Grey,
                    ),

                    const SizedBox(height: 35),

                    Center(child: _buildDemoCard(index)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                            (dot) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentIndex == dot ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentIndex == dot
                                ? AppColors.primarycolor
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primarycolor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          currentIndex == 2
                              ? "start_now".tr()
                              : "next".tr(),
                          style: AppStyles.bold20White,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDemoCard(int page) {
    switch (page) {
      case 0:
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.whitecolor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sessionTile("strength_training".tr(), "today_6pm".tr(), true),
              const SizedBox(height: 12),
              _sessionTile("swimming".tr(), "tomorrow_730am".tr(), false),
              const SizedBox(height: 12),
              _sessionTile("yoga".tr(), "thursday_5pm".tr(), false),
            ],
          ),
        );

      case 1:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _activity(Icons.access_time),
            _activity(Icons.pool),
            _activity(Icons.fitness_center),
          ],
        );

      default:
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.whitecolor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("current_subscription".tr(), style: AppStyles.bold16Black),
              const SizedBox(height: 18),
              Row(
                children: List.generate(
                  5,
                      (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 8,
                      decoration: BoxDecoration(
                        color: index < 3
                            ? AppColors.primarycolor
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("sessions_this_month".tr(), style: AppStyles.bold20Primary),
            ],
          ),
        );
    }
  }

  Widget _sessionTile(String title, String time, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.whitecolor : const Color(0xffF7F6F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: active ? AppColors.primarycolor : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              active ? Icons.close : Icons.circle_outlined,
              color: active ? AppColors.yellowcolor : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: AppStyles.bold16Black),
                const SizedBox(height: 4),
                Text(time, style: AppStyles.regular14Grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activity(IconData icon) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.whitecolor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 36, color: AppColors.primarycolor),
    );
  }
}