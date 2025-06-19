// return GestureDetector(
//   onLongPress: () => _toggleReaction(messages[index].id, '❤️'),
//   child: Container(
//     margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//     alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//     child: ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 300),
//       child: Column(
//         crossAxisAlignment:
//             isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: msg.type == 'image'
//                 ? EdgeInsets.zero
//                 : const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//             decoration: BoxDecoration(
//               color: msg.type == 'image'
//                   ? Colors.transparent
//                   : (isMe
//                       ? const Color(0xFFDCF8C6)
//                       : const Color(0xFFFFFFFF)),
//               borderRadius: BorderRadius.only(
//                 topLeft: const Radius.circular(12),
//                 topRight: const Radius.circular(12),
//                 bottomLeft: Radius.circular(isMe ? 12 : 0),
//                 bottomRight: Radius.circular(isMe ? 0 : 12),
//               ),
//             ),
//             child: msg.type == 'image' && msg.imageUrl != null
//                 ? Stack(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: CachedNetworkImage(
//                           imageUrl: msg.imageUrl!,
//                           width: MediaQuery.of(context).size.width * 0.7,
//                           height: 300,
//                           fit: BoxFit.cover,
//                           placeholder: (context, url) => const Center(
//                             child: Padding(
//                               padding: EdgeInsets.all(20),
//                               child: CircularProgressIndicator(),
//                             ),
//                           ),
//                           errorWidget: (context, url, error) =>
//                               const Icon(Icons.error),
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 6,
//                         right: 8,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: Colors.black45,
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 DateFormat('h:mm a').format(msg.timestamp),
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                               const SizedBox(width: 4),
//                               Icon(
//                                 msg.isRead
//                                     ? Icons.done_all
//                                     : msg.isDelivered
//                                         ? Icons.done_all
//                                         : Icons.check,
//                                 size: 14,
//                                 color: msg.isRead
//                                     ? Colors.blue
//                                     : Colors.white.withOpacity(0.7),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 : Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         msg.message,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           Text(
//                             DateFormat('h:mm a').format(msg.timestamp),
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Color(0xFF7A7A7A),
//                             ),
//                           ),
//                           const SizedBox(width: 4),
//                           if (isMe)
//                             Icon(
//                               msg.isRead
//                                   ? Icons.done_all
//                                   : msg.isDelivered
//                                       ? Icons.done_all
//                                       : Icons.check,
//                               size: 18,
//                               color: msg.isRead
//                                   ? Colors.blue
//                                   : Colors.grey,
//                             ),
//                         ],
//                       ),
//                     ],
//                   ),
//           ),
//           if (reactions.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(
//                   left: 12, right: 12, top: 2, bottom: 4),
//               child: Text(
//                 reactions.values.join(' '),
//                 style: const TextStyle(fontSize: 14),
//               ),
//             ),
//         ],
//       ),
//     ),
//   ),
// );
