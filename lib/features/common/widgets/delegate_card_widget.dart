import 'package:flutter/material.dart';

import '../../../config/app_config.dart';

class DelegateCard extends StatelessWidget {
  final Map<String, dynamic> delegate;

  const DelegateCard({super.key, required this.delegate});

  @override
  Widget build(BuildContext context) {
    final delegateName =
        delegate['delegate_name']?.toString() ?? 'Unknown Delegate';
    final designation = delegate['designation']?.toString() ?? '';
    final companyName = delegate['company_name']?.toString() ?? '';
    final profilePic = delegate['profile_pic']?.toString();
    final isUsingApp = delegate['is_using_app']?.toString() ?? '';
    final openForAppointment =
        delegate['open_for_appointment'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delegate Header with Photo and Basic Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                    '${appConfig.storageUrl}/$profilePic',
                  ),
                ),
                const SizedBox(width: 16),
                // Delegate Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delegateName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      if (designation.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          designation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (companyName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Status Indicators
            if (openForAppointment || isUsingApp.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (openForAppointment) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Color(0xFF4CAF50),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Available for Appointment',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isUsingApp.isNotEmpty &&
                      !isUsingApp.contains('not using')) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2196F3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 12,
                            color: Color(0xFF2196F3),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Using App',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
