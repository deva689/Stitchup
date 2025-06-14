// import 'package:flutter/material.dart';

// class Trndx extends StatefulWidget {
//   const Trndx({super.key});

//   @override
//   State<Trndx> createState() => _TrndxState();
// }

// class _TrndxState extends State<Trndx> with TickerProviderStateMixin {
//   late AnimationController _controller;
//   bool _isExpanded = false;

//   final List<_FabItem> fabItems = [
//     _FabItem(icon: Icons.videocam, label: "Go Live"),
//     _FabItem(icon: Icons.mic, label: "Spaces"),
//     _FabItem(icon: Icons.photo, label: "Photos"),
//     _FabItem(icon: Icons.edit, label: "Post"),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//   }

//   void _toggleFab() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//       _isExpanded ? _controller.forward() : _controller.reverse();
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Widget _buildAnimatedFabItem(int index, _FabItem item) {
//     final intervalStart = index * 0.1;
//     final intervalEnd = intervalStart + 0.5;

//     final Animation<double> animation = CurvedAnimation(
//       parent: _controller,
//       curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOut),
//     );

//     return AnimatedBuilder(
//       animation: animation,
//       builder: (_, child) {
//         return Transform.translate(
//           offset: Offset(0, -animation.value * (65.0 * (index + 1))),
//           child: Opacity(
//             opacity: animation.value,
//             child: Transform.scale(
//               scale: animation.value,
//               child: child,
//             ),
//           ),
//         );
//       },
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             margin: const EdgeInsets.only(right: 10),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: const [
//                 BoxShadow(color: Colors.black12, blurRadius: 4),
//               ],
//             ),
//             child: Text(item.label,
//                 style: const TextStyle(fontWeight: FontWeight.w500)),
//           ),
//           FloatingActionButton(
//             mini: true,
//             heroTag: item.label,
//             onPressed: () {},
//             backgroundColor: Colors.white,
//             foregroundColor: Colors.black,
//             child: Icon(item.icon),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: ListView.builder(
//         itemCount: 10,
//         padding: const EdgeInsets.all(12),
//         itemBuilder: (context, index) {
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 8),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             elevation: 2,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ListTile(
//                   leading: CircleAvatar(backgroundColor: Colors.grey[300]),
//                   title: Text("User $index",
//                       style: const TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: const Text("2h ago"),
//                   trailing: const Icon(Icons.more_vert),
//                 ),
//                 Container(
//                   height: 200,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   margin: const EdgeInsets.all(12),
//                 ),
//                 Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: const [
//                       Icon(Icons.favorite_border),
//                       Icon(Icons.chat_bubble_outline),
//                       Icon(Icons.repeat),
//                       Icon(Icons.share),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//      floatingActionButton: Stack(
//   alignment: Alignment.bottomRight,
//   children: [
//     ...List.generate(
//       fabItems.length,
//       (index) => _buildAnimatedFabItem(
//         index,
//         fabItems[index],
//         heroTag: 'fab_item_$index', // Pass unique tag
//       ),
//     ),
//     FloatingActionButton(
//       heroTag: 'main_fab', // UNIQUE TAG FOR MAIN FAB
//       backgroundColor: const Color(0xFFd4ed6e), // Light yellow-green
//       shape: const CircleBorder(),
//       onPressed: _toggleFab,
//       child: Icon(_isExpanded ? Icons.close : Icons.add),
//     ),

//         ],
//       ),
//     );
//   }
// }

// class _FabItem {
//   final IconData icon;
//   final String label;

//   const _FabItem({required this.icon, required this.label});
// }
