import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/quiet_profile.dart';

class ProfileCard extends StatelessWidget {
  final QuietProfile profile;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onToggle,
    required this.onTap,
  });

  String _formatNextSchedule() {
    final next = profile.nextScheduledTime;
    if (next == null) return 'No upcoming schedule';

    final now = DateTime.now();
    final diff = next.difference(now);

    if (diff.inMinutes < 60) {
      return 'Next: in ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Next: in ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      final dayFormat = DateFormat('EEE, h:mm a');
      return 'Next: ${dayFormat.format(next)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: profile.isEnabled
                      ? const Color(0xFF7C4DFF).withValues(alpha: 0.2)
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  profile.iconData,
                  color: profile.isEnabled
                      ? const Color(0xFF7C4DFF)
                      : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: profile.isEnabled
                            ? Colors.white
                            : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.startTimeFormatted} - ${profile.endTimeFormatted}',
                      style: TextStyle(
                        fontSize: 13,
                        color: profile.isEnabled
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.activeDaysSummary,
                      style: TextStyle(
                        fontSize: 12,
                        color: profile.isEnabled
                            ? Colors.grey[500]
                            : Colors.grey[700],
                      ),
                    ),
                    if (profile.isEnabled) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatNextSchedule(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C4DFF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: profile.isEnabled,
                onChanged: onToggle,
                activeTrackColor: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                activeThumbColor: const Color(0xFF7C4DFF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
