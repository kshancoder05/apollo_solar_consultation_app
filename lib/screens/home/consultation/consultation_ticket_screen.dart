import 'package:flutter/material.dart';

class ConsultationTicketScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const ConsultationTicketScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final ref = booking['ref'] ?? 'N/A';
    final client = booking['client'] ?? 'Client';

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket $ref'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              client,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Consultation tracker is ready for the next stage of the workflow.'),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Status'),
                subtitle: Text('${booking['status'] ?? 'Pending'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
