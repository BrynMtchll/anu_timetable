// import 'dart:async';

// import 'package:dropdown_recreation/custom_dropdown_route.dart';
// import 'package:flutter/material.dart';

// import 'dropdown_item.dart';



// typedef DropdownItemSelectedCallback<T> = void Function(String key, DropdownItem<T> selectedItem);
// typedef DropdownItemBuilder<T> = Widget Function(DropdownItem<T> selectedItem, bool isForRootButton);


// class DropdownItem<T> {
//   final T? _value;
//   final String? staticValue;
//   final String? groupTitle;

//   bool get isStatic => staticValue != null;

//   bool get isGroupTitle => groupTitle != null;

//   T get value {
//     final value = _value;
//     if (value == null) {
//       throw StateError('This is a static instance and does not have a value');
//     }
//     return value;
//   }

//   const DropdownItem._({T? value, this.staticValue, this.groupTitle})
//       : _value = value;

//   const DropdownItem.static([String? staticValue]) : this._(staticValue: staticValue);

//   const DropdownItem.dynamic(T value) : this._(value: value);

//   const DropdownItem.groupTitle(String groupTitle) : this._(groupTitle: groupTitle);
// }

// class CustomDropdown<T> extends StatefulWidget {
//   /// A map of items that the user can select from.
//   final Map<String, DropdownItem<T>> options;

//   /// Callback that is called when an item is selected.
//   final DropdownItemSelectedCallback<T> itemSelected;

//   /// A builder that returns a widget to display for a dropdown item.
//   final DropdownItemBuilder<T> itemBuilder;

//   /// A notifier that holds the currently selected key. Allows us to rebuild the widget when the selected key changes.
//   final ValueNotifier<String?> selectedKey;

//   /// Whether this dropdown is enabled or not. If false, the dropdown will be disabled and not respond to taps.
//   final bool enabled;

//   /// Whether the dropdown is currently loading. If true, a loading indicator will be shown instead of the dropdown icon.
//   final bool isLoading;

//   const CustomDropdown({
//     required this.options,
//     required this.itemSelected,
//     required this.selectedKey,
//     required this.itemBuilder,
//     this.enabled = true,
//     this.isLoading = false,
//     super.key,
//   });

//   @override
//   State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
// }

// class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
//   var isOpen = false;

//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: widget.selectedKey,
//       builder: (BuildContext context, Widget? child) {
//         return ElevatedButton(
//           onPressed: widget.enabled ? _onRootButtonPressed : null,
//           child: Row(
//             children: [
//               Expanded(child: widget.selectedKey.value != null ? _buildSelectedItem : Text('Select an option')),
//               _trailingWidget,
//             ],
//           ),
//         );
//       },
//     );
//   }

//   /// Use the delegated builder to create a widget for the selected item.
//   Widget get _buildSelectedItem {
//     // Do proper null handling here, using ! for brevity in this example
//     return widget.itemBuilder(widget.options[widget.selectedKey.value!]!, true);
//   }

//   /// Returns the trailing widget, which is either a loading indicator or an arrow icon.
//   Widget get _trailingWidget {
//     if (widget.isLoading) {
//       return SizedBox(width: 24, height: 24, child: CircularProgressIndicator());
//     }
//     return Icon(Icons.arrow_drop_down);
//   }

//   /// Handles the button press to open the dropdown.
//   Future<void> _onRootButtonPressed() async {
//     setState(() => isOpen = true);
//     // Push the route and await the return just like the Material dropdown does
//     var route = CustomDropdownRoute<T>(
//       options: widget.options,
//       itemSelected: _onItemSelected,
//       itemBuilder: widget.itemBuilder,
//       sourceButtonRect: _renderRect,
//     );
//     await Navigator.push(context, route);
//     await route.popped;
//     setState(() => isOpen = false);
//   }

//   void _onItemSelected(String key, DropdownItem<T> item) {
//     // Close the dropdown and notify the parent widget of the selection
//     Navigator.pop(context);
//     widget.itemSelected(key, item);
//   }

//   /// Get the rect of this object in the global coordinate system.
//   /// This is used to position the dropdown list correctly.
//   Rect get _renderRect {
//     final navigator = Navigator.of(context);
//     final navigatorBox = navigator.context.findRenderObject();
//     final buttonBox = context.findRenderObject();
//     if (buttonBox is! RenderBox) {
//       throw AssertionError('Button box was null when trying to get render rect.');
//     }

//     return buttonBox.localToGlobal(Offset.zero, ancestor: navigatorBox) & buttonBox.size;
//   }
// }