import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/responsive.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: responsive.width(20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w600,
            fontFamily: 'DM Sans',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: responsive.paddingSymmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: responsive.spacing(20)),
            Text(
              'How can we help you?',
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.fontSize(28),
                fontWeight: FontWeight.w700,
                fontFamily: 'DM Sans',
                height: 1.2,
              ),
            ),
            SizedBox(height: responsive.spacing(12)),
            Text(
              'Have a question or need assistance? Our team is here to support you 24/7.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: responsive.fontSize(16),
                fontWeight: FontWeight.w400,
                fontFamily: 'DM Sans',
              ),
            ),
            SizedBox(height: responsive.spacing(40)),
            
            // Support Options
            _buildSupportOption(
              context: context,
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@colleezy.com',
              onTap: () => _launchUrl('mailto:support@colleezy.com'),
            ),
            _buildSupportOption(
              context: context,
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              subtitle: '+1 234 567 890',
              onTap: () => _launchUrl('tel:+1234567890'),
            ),
            _buildSupportOption(
              context: context,
              icon: Icons.chat_bubble_outline,
              title: 'WhatsApp Support',
              subtitle: 'Chat with us instantly',
              onTap: () => _launchUrl('https://wa.me/1234567890'),
            ),
            
            SizedBox(height: responsive.spacing(40)),
            Text(
              'FAQs',
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.fontSize(20),
                fontWeight: FontWeight.w600,
                fontFamily: 'DM Sans',
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
            
            _buildFaqItem(
              context: context,
              question: 'How do I create a group?',
              answer: 'Tap the "+" icon on the home screen and follow the steps to set up your Kuri group.',
            ),
            _buildFaqItem(
              context: context,
              question: 'How are winners drawn?',
              answer: 'Winners can be drawn manually by the agent or automatically based on the schedule you set.',
            ),
            _buildFaqItem(
              context: context,
              question: 'Is my data secure?',
              answer: 'Yes, we use industry-standard encryption to ensure your data and transactions are always protected.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final responsive = Responsive(context);
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacing(16.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        child: Container(
          padding: responsive.paddingAll(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(responsive.radius(16)),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: responsive.paddingAll(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D7A4F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF2D7A4F), size: responsive.width(24)),
              ),
              SizedBox(width: responsive.spacing(20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    SizedBox(height: responsive.spacing(4)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.w400,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: responsive.width(16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({required BuildContext context, required String question, required String answer}) {
    final responsive = Responsive(context);
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacing(16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              fontFamily: 'DM Sans',
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            answer,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.w400,
              fontFamily: 'DM Sans',
              height: 1.5,
            ),
          ),
          SizedBox(height: responsive.spacing(16)),
          Divider(color: Colors.white.withOpacity(0.05)),
        ],
      ),
    );
  }
}
