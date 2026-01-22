import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../../utils/responsive.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final success = await _apiService.markNotificationAsRead(id);
      if (success && mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == id);
          if (index != -1) {
            _notifications[index]['is_read'] = true;
          }
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final count = await _apiService.markAllNotificationsAsRead();
      if (count > 0 && mounted) {
        setState(() {
          for (var n in _notifications) {
            n['is_read'] = true;
          }
        });
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM d, h:mm a').format(dateTime);
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F1A),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: responsive.fontSize(18),
            fontFamily: 'DM Sans',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: responsive.width(24)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFF7FDE68),
                  fontSize: responsive.fontSize(12),
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: const Color(0xFF7FDE68),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF7FDE68)))
            : _notifications.isEmpty
                ? _buildEmptyState(context)
                : _buildNotificationsList(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final responsive = Responsive(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: responsive.width(64),
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: responsive.spacing(16)),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.8),
              fontSize: responsive.fontSize(16),
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context) {
    final responsive = Responsive(context);
    return ListView.separated(
      padding: responsive.paddingAll(16),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => SizedBox(height: responsive.spacing(12)),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final isRead = notification['is_read'] as bool? ?? false;

        return GestureDetector(
          onTap: () {
            if (!isRead) {
              _markAsRead(notification['id'] as int);
            }
          },
          child: Container(
            padding: responsive.paddingAll(16),
            decoration: BoxDecoration(
              color: isRead ? Color(0xFF2A2A2A).withOpacity(0.5) : Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(responsive.radius(16)),
              border: isRead
                  ? null
                  : Border.all(color: Color(0xFF7FDE68).withOpacity(0.3), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: responsive.paddingAll(10),
                  decoration: BoxDecoration(
                    color: isRead 
                        ? Colors.grey.withOpacity(0.1) 
                        : Color(0xFF7FDE68).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: isRead ? Colors.grey : Color(0xFF7FDE68),
                    size: responsive.width(20),
                  ),
                ),
                SizedBox(width: responsive.spacing(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? 'Notification',
                              style: TextStyle(
                                color: isRead ? Colors.grey : Colors.white,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: responsive.fontSize(16),
                                fontFamily: 'DM Sans',
                              ),
                            ),
                          ),
                          Text(
                            _formatDateTime(notification['created_at']),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: responsive.fontSize(12),
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(4)),
                      Text(
                        notification['message'] ?? '',
                        style: TextStyle(
                          color: isRead ? Colors.grey : Color(0xFFE0DED9),
                          fontSize: responsive.fontSize(14),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: responsive.width(8),
                    height: responsive.height(8),
                    margin: EdgeInsets.only(left: responsive.spacing(8), top: responsive.spacing(4)),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7FDE68),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
