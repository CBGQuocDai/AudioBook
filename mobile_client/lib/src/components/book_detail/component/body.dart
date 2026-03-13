import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/book_detail_provider.dart';

class BookDetailBody extends StatelessWidget {
  const BookDetailBody({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookDetailProvider>();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          Container(
            height: 220,
            width: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage("assets/images/The Midnight Library.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "The Midnight Library",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "by Matt Haig",
            style: TextStyle(color: Colors.orange),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.star, color: Colors.orange, size: 18),
              SizedBox(width: 4),
              Text("4.8 (2.4k)"),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.menu_book),
                label: const Text("Read Now"),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: () {},
                icon: const Icon(Icons.headphones),
                label: const Text("Listen Now"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => provider.changeTab(0),
                child: Column(
                  children: [
                    Text(
                      "About",
                      style: TextStyle(
                        color: provider.currentTab == 0
                            ? Colors.orange
                            : Colors.grey,
                      ),
                    ),
                    if (provider.currentTab == 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: 40,
                        color: Colors.orange,
                      )
                  ],
                ),
              ),
              const SizedBox(width: 40),
              GestureDetector(
                onTap: () => provider.changeTab(1),
                child: Column(
                  children: [
                    Text(
                      "Chapter",
                      style: TextStyle(
                        color: provider.currentTab == 1
                            ? Colors.orange
                            : Colors.grey,
                      ),
                    ),
                    if (provider.currentTab == 1)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: 50,
                        color: Colors.orange,
                      )
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          provider.currentTab == 0 ? _about() : _chapters(),
        ],
      ),
    );
  }

  Widget _about() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        "Between life and death there is a library, and within that library, "
            "the shelves go on forever. Every book provides a chance to try "
            "another life you could have lived.",
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _chapters() {
    final chapters = [
      "The Beginning",
      "The Hidden Path",
      "Into The Wild",
      "The Golden Sunset",
      "Voices in the Mist",
      "The Summit",
      "The Descent",
      "Homecoming"
    ];

    return ListView.builder(
      itemCount: chapters.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, i) {
        return ListTile(
          leading: Text("${i + 1}".padLeft(2, '0')),
          title: Text(chapters[i]),
        );
      },
    );
  }
}