import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsItem;

  const NewsDetailScreen({super.key, required this.newsItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: newsItem['image_url'] != null 
                ? Hero(
                    tag: 'news_image_${newsItem['id']}',
                    child: Image.network(newsItem['image_url'], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300)),
                  )
                : Container(color: const Color(0xFF4F46E5)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(newsItem['title'] ?? '', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: const Color(0xFFEEF2FF), child: const Icon(Icons.person, color: Color(0xFF4F46E5))),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(newsItem['author'] ?? 'Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          Text('Nguồn uy tín - KNS 4.0', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                    child: Text(newsItem['summary'] ?? '', style: GoogleFonts.outfit(fontStyle: FontStyle.italic, fontSize: 15, color: Colors.amber.shade900)),
                  ),
                  const SizedBox(height: 24),
                  Text(newsItem['content'] ?? '', style: GoogleFonts.outfit(fontSize: 16, height: 1.6, color: Colors.grey.shade800)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
