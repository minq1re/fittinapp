import 'package:flutter/material.dart';

class ExpandableSection extends StatefulWidget {
  final String title;
  final Widget? child;
  final bool initiallyExpanded;

  const ExpandableSection({
    Key? key,
    required this.title,
    this.child,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool expanded;

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => expanded = !expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF954B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2D2D2D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF2D2D2D),
                  ),
                ],
              ),
            ),
          ),
          if (expanded && widget.child != null)
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFFFD5B8),
              child: widget.child,
            ),
        ],
      ),
    );
  }
} 