import 'package:flutter/material.dart';

class ImpressionPage extends StatefulWidget {
  const ImpressionPage({super.key});

  @override
  State<ImpressionPage> createState() => _ImpressionPageState();
}

class _ImpressionPageState extends State<ImpressionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulasi delay pengiriman
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih atas kesan dan pesan Anda!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Clear form
      _nameController.clear();
      _nimController.clear();
      _messageController.clear();

      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kesan & Pesan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            
            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Naimatul Ulumiyah',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[900],
                                height: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ), 
                      child: Row(
                        children: 
                        [
                          Icon(Icons.numbers, color: Colors.blue[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '124230042',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[900],
                                height: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nama Field
                    const Text(
                      'Kesan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[900],
                                height: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}