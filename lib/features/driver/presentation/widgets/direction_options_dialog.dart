import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectionOptionsDialog extends StatelessWidget {
  final String destinationLat;
  final String destinationLong;
  final String destinationName;

  const DirectionOptionsDialog({
    super.key,
    required this.destinationLat,
    required this.destinationLong,
    required this.destinationName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Navigation App',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destinationName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Navigation Options
            _buildNavigationOption(
              context,
              icon: 'assets/google_maps_icon.png',
              fallbackIcon: Icons.map,
              title: 'Google Maps',
              subtitle: 'Open in Google Maps',
              color: Colors.red.shade600,
              onTap: () async {
                await _launchGoogleMaps(context);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 12),
            _buildNavigationOption(
              context,
              icon: 'assets/waze_icon.png',
              fallbackIcon: Icons.navigation,
              title: 'Waze',
              subtitle: 'Open in Waze',
              color: Colors.blue.shade600,
              onTap: () async {
                await _launchWaze(context);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 12),
            _buildNavigationOption(
              context,
              icon: 'assets/wain_icon.png',
              fallbackIcon: Icons.location_on,
              title: 'Wain',
              subtitle: 'Open in Wain',
              color: Colors.green.shade600,
              onTap: () async {
                await _launchWain(context);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 24),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationOption(
    BuildContext context, {
    required String icon,
    required IconData fallbackIcon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // App Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(fallbackIcon, color: color, size: 24)),
            ),
            const SizedBox(width: 16),
            // App Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGoogleMaps(BuildContext context) async {
    final url =
        'http://maps.google.com/maps?q=$destinationLat,$destinationLong';
    await _launchUrl(context, url, appName: 'Google Maps');
  }

  Future<void> _launchWaze(BuildContext context) async {
    final wazeUrl = 'waze://?ll=$destinationLat,$destinationLong&navigate=yes';
    final webUrl = 'https://ul.waze.com/ul?ll=$destinationLat,$destinationLong';
    // if (await canLaunchUrl(Uri.parse(webUrl))) {
    await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    // } else if (await canLaunchUrl(Uri.parse(wazeUrl))) {
    //   await launchUrl(
    //     Uri.parse(wazeUrl),
    //     mode: LaunchMode.externalNonBrowserApplication,
    //   );
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Waze app not found.'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
  }

  Future<void> _launchWain(BuildContext context) async {
    final url =
        'https://wain.qmic.com/share/Location?type=101&lat=$destinationLat&lng=$destinationLong';
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalNonBrowserApplication,
    );
  }

  Future<void> _launchUrl(
    BuildContext context,
    String url, {
    String? appName,
  }) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${appName ?? 'Navigation app'} not found.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
