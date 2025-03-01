import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/journal.dart';
import '../providers/journals_provider.dart';

class JournalEditorScreen extends ConsumerStatefulWidget {
  final Journal? journal;

  const JournalEditorScreen({this.journal, super.key});

  @override
  ConsumerState<JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  late TextEditingController _contentController;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    _contentController = TextEditingController(
      text: widget.journal?.encryptedContent,
    );

    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!mounted) return;

    final hasChanges =
        widget.journal != null
            ? _contentController.text != widget.journal!.encryptedContent
            : _contentController.text.isNotEmpty;

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Discard'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  Future<void> _saveJournal() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.journal != null) {
        await ref
            .read(journalOperationsProvider)
            .updateJournal(widget.journal!, _contentController.text);
      } else {
        await ref
            .read(journalOperationsProvider)
            .addJournal(_contentController.text);
      }

      if (mounted) {
        setState(() => _hasChanges = false); // Clear the changes flag
        context.pop(); // Remove the boolean parameter
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return PopScope(
      onPopInvokedWithResult: (bool t, _) async {
        final canPop = await _onWillPop();
        if (canPop && mounted) {
          context.pop(t);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            widget.journal != null ? 'Edit Entry' : 'New Entry',
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed:
                () => _onWillPop().then((canPop) {
                  if (canPop && mounted) context.pop();
                }),
          ),
          actions: [if (_hasChanges) _buildUnsavedIndicator()],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              hintText: 'Write your thoughts...',
                              contentPadding: const EdgeInsets.all(16),
                              border: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: true,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildBottomBar(false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return PopScope(
      onPopInvokedWithResult: (bool t, _) {
        _onWillPop().then((canPop) {
          if (canPop) context.pop(t);
        });
      },
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              // Left sidebar
              Container(
                width: 400,
                color: Theme.of(context).primaryColor,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed:
                              () => _onWillPop().then((canPop) {
                                if (canPop) context.pop();
                              }),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.journal != null ? 'Edit Entry' : 'New Entry',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_hasChanges) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Unsaved Changes',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                    const Spacer(),
                    _buildBottomBar(true),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildContentField(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: TextField(
              controller: _contentController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Write your thoughts...',
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnsavedIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Unsaved',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed:
                  () => _onWillPop().then((canPop) {
                    if (canPop) context.pop();
                  }),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color:
                      isDesktop
                          ? Colors.white70
                          : Theme.of(context).primaryColor,
                ),
                foregroundColor:
                    isDesktop ? Colors.white70 : Theme.of(context).primaryColor,
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _hasChanges && !_isLoading ? _saveJournal : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child:
                  _isLoading
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                      : Text(
                        'Save',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
