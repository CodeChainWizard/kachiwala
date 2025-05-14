import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define the counter provider
final counterProvider = StateProvider<int>((ref) => 0);

// void updateCounter(WidgetRef ref, bool isSelected) {
//   final counter = ref.read(counterProvider.notifier); // Access the StateController
//   int currentValue = counter.state; // Get the current value of the counter
//
//   if (isSelected) {
//     counter.state = currentValue + 1; // Increment the counter
//   } else {
//     counter.state = currentValue - 1; // Decrement the counter, ensuring it doesn't go negative
//     if (counter.state < 0) counter.state = 0;
//   }
//
//   print("Counter Updated: ${counter.state}");
// }


// void updateCounter(WidgetRef ref, bool isSelected) {
//   final counter = ref.read(counterProvider.notifier);
//   int oldValue = counter.state;
//
//   if (isSelected) {
//     counter.state++;
//   } else {
//     counter.state--;
//     if (counter.state < 0) counter.state = 0;
//   }
//
//   if (oldValue != counter.state) {
//     print("Counter Updated In RiverPod: ${counter.state}");
//   }
// }
