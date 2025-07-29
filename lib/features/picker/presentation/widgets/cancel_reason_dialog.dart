import 'package:flutter/material.dart';

class CancelReasonDialog extends StatefulWidget {
  const CancelReasonDialog({super.key});

  @override
  State<CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<CancelReasonDialog> {
  String? selectedReason;
  final TextEditingController _customReasonController = TextEditingController();

  final List<Map<String, String>> cancelReasons = [
    {
      'id': 'out_of_stock',
      'title': 'Out of Stock',
      'description': 'Items are not available in inventory',
      'icon': '📦',
    },
    {
      'id': 'damaged_items',
      'title': 'Damaged Items',
      'description': 'Items are damaged or defective',
      'icon': '💔',
    },
    {
      'id': 'quality_issues',
      'title': 'Quality Issues',
      'description': 'Items do not meet quality standards',
      'icon': '⚠️',
    },
    {
      'id': 'expired_items',
      'title': 'Expired Items',
      'description': 'Items have passed expiration date',
      'icon': '⏰',
    },
    {
      'id': 'wrong_items',
      'title': 'Wrong Items',
      'description': 'Items received are different from ordered',
      'icon': '❌',
    },
    {
      'id': 'customer_request',
      'title': 'Customer Request',
      'description': 'Customer requested cancellation',
      'icon': '👤',
    },
    {
      'id': 'technical_issue',
      'title': 'Technical Issue',
      'description': 'System or technical problem',
      'icon': '🔧',
    },
    {
      'id': 'other',
      'title': 'Other',
      'description': 'Other reason (please specify)',
      'icon': '📝',
    },
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cancel_outlined,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel Order Request',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please select a reason for cancellation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Reason:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason options
                    ...cancelReasons.map(
                      (reason) => _buildReasonOption(reason),
                    ),

                    const SizedBox(height: 20),

                    // Custom reason input
                    if (selectedReason == 'other') ...[
                      Text(
                        'Please specify the reason:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customReasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter your reason for cancellation...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red.shade400),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          selectedReason != null &&
                                  (selectedReason != 'other' ||
                                      _customReasonController.text.isNotEmpty)
                              ? () => _submitCancelRequest()
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption(Map<String, String> reason) {
    final isSelected = selectedReason == reason['id'];
    final isOther = reason['id'] == 'other';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedReason = reason['id'];
            if (!isOther) {
              _customReasonController.clear();
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.red.shade300 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio button
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? Colors.red.shade600 : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade600,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 16),

              // Icon
              Text(reason['icon']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason['title']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected
                                ? Colors.red.shade800
                                : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason['description']!,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isSelected
                                ? Colors.red.shade600
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitCancelRequest() {
    if (selectedReason == null) {
      // Show error if no reason is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cancel reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String finalReason = selectedReason!;
    if (selectedReason == 'other' && _customReasonController.text.isNotEmpty) {
      finalReason = _customReasonController.text.trim();
    } else if (selectedReason == 'other' &&
        _customReasonController.text.isEmpty) {
      // Show error if "Other" is selected but no custom reason provided
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a custom reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Return the result with proper null safety
    Navigator.of(
      context,
    ).pop({'reason': finalReason, 'reasonId': selectedReason});
  }
}
