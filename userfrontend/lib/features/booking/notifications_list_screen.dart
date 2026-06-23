import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/models/notification_model.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Consumer<NotificationProvider>(
                          builder: (context, provider, child) {
                            if (provider.unreadCount > 0) {
                              return Text(
                                '${provider.unreadCount} unread',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ],
                    ),
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, provider, child) {
                      if (provider.unreadCount > 0) {
                        return TextButton(
                          onPressed: () => provider.markAllAsRead(),
                          child: const Text(
                            'Mark all read',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<NotificationProvider>().fetchNotifications(),
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.error != null &&
                        provider.notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${provider.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.fetchNotifications(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (provider.notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = provider.notifications[index];
                        return NotificationCard(
                          notification: notification,
                          onMarkRead: () =>
                              provider.markAsRead(notification.id),
                          onDelete: () =>
                              provider.deleteNotification(notification.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'ride':
        return Icons.directions_car;
      case 'payment':
        return Icons.payment;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'ride':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'promo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Unknown time';
    }
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getColorForType(notification.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForType(notification.type),
              color: _getColorForType(notification.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: AppColors.grey600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.createdAt),
                  style: TextStyle(
                    color: AppColors.grey600.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!notification.isRead)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: Colors.green,
                  onPressed: onMarkRead,
                  tooltip: 'Mark as read',
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[300],
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
