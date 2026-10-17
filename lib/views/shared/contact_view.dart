import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/models/store_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:url_launcher/url_launcher.dart';

/// How to reach the academy: the unified number first, then WhatsApp and
/// the rest. Everything comes from the organisation settings on the panel.
class ContactView extends StatefulWidget {
  const ContactView({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactView()));

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  ContactModel? _contact;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await ApiClient.instance.get(ApiEndpoints.contact);
      if (!mounted) return;
      setState(() => _contact = ContactModel.fromJson(Map<String, dynamic>.from(r['contact'] ?? {})));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _go(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('something_went_wrong'.tr())));
    }
  }

  static String _digits(String v) => v.replaceAll(RegExp(r'[^0-9+]'), '');

  @override
  Widget build(BuildContext context) {
    final c = _contact;
    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      appBar: AppBar(title: Text('contact_us'.tr())),
      body: c == null
          ? AsyncStateView(isLoading: _error == null, errorMessage: _error, onRetry: _load, child: const SizedBox())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (c.unifiedNumber != null)
                  ClubGradientPanel(
                    child: InkWell(
                      onTap: () => _go('tel:${_digits(c.unifiedNumber!)}'),
                      child: Row(children: [
                        const Icon(Icons.support_agent_rounded, color: Colors.white, size: 34),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('unified_number'.tr(), style: AppStyles.bold11Gold),
                            const SizedBox(height: 4),
                            Text(c.unifiedNumber!, style: AppStyles.bold24White),
                          ]),
                        ),
                        const Icon(Icons.call_rounded, color: Colors.white),
                      ]),
                    ),
                  ),
                const SizedBox(height: 12),
                if (c.whatsappUrl != null)
                  _row(Icons.chat_rounded, 'whatsapp'.tr(), 'whatsapp_desc'.tr(), () => _go(c.whatsappUrl!), color: AppColors.greencolor),
                if (c.phone != null)
                  _row(Icons.phone_rounded, 'phone'.tr(), c.phone!, () => _go('tel:${_digits(c.phone!)}')),
                if (c.email != null)
                  _row(Icons.mail_rounded, 'email'.tr(), c.email!, () => _go('mailto:${c.email}')),
                if (c.website != null)
                  _row(Icons.language_rounded, 'website'.tr(), c.website!.replaceFirst(RegExp(r'^https?://'), ''), () => _go(c.website!)),
                if (c.address != null)
                  _row(Icons.location_on_rounded, 'address'.tr(), c.address!, null),
                if (c.unifiedNumber == null && c.whatsappUrl == null && c.phone == null && c.email == null)
                  ClubCard(
                    child: EmptyState(
                      icon: Icons.contact_support_outlined,
                      title: 'contact_unavailable'.tr(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _row(IconData icon, String title, String value, VoidCallback? onTap, {Color? color}) {
    return ClubCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: .14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color ?? AppColors.goldInk, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppStyles.bold14Black),
            const SizedBox(height: 2),
            Text(value, style: AppStyles.regular12Grey),
          ]),
        ),
        if (onTap != null) Icon(Icons.chevron_right_rounded, color: AppColors.greycolor),
      ]),
    );
  }
}
