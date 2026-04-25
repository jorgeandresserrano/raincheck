import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raincheck/src/data/location_service.dart';
import 'package:raincheck/src/domain/raincheck_models.dart';
import 'package:raincheck/src/state/raincheck_state.dart';
import 'package:raincheck/src/theme/raincheck_theme.dart';

class LocationSearchField extends ConsumerStatefulWidget {
  const LocationSearchField({
    super.key,
    required this.onSelected,
    this.initialQuery = '',
    this.textFieldKey,
    this.suggestionKeyPrefix = 'location-suggestion',
    this.dark = false,
  });

  final ValueChanged<LocationSuggestion?> onSelected;
  final String initialQuery;
  final Key? textFieldKey;
  final String suggestionKeyPrefix;
  final bool dark;

  @override
  ConsumerState<LocationSearchField> createState() =>
      _LocationSearchFieldState();
}

class _LocationSearchFieldState extends ConsumerState<LocationSearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<LocationSuggestion> _suggestions = const [];
  LocationSuggestion? _selected;
  String? _message;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.dark ? Colors.white : RainCheckColors.ink;
    final mutedColor =
        widget.dark
            ? Colors.white.withValues(alpha: 0.72)
            : RainCheckColors.mutedInk;
    final borderColor =
        widget.dark
            ? Colors.white.withValues(alpha: 0.24)
            : Theme.of(context).colorScheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: widget.textFieldKey,
          controller: _controller,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'City or address',
            helperText: 'Choose one of the suggestions below.',
            labelStyle: TextStyle(color: mutedColor),
            helperStyle: TextStyle(color: mutedColor),
            suffixIcon:
                _controller.text.isEmpty
                    ? null
                    : IconButton(
                      key: const Key('location-clear-button'),
                      tooltip: 'Clear location search',
                      onPressed: _clearQuery,
                      icon: const Icon(Icons.close),
                    ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RainCheckRadii.card),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RainCheckRadii.card),
              borderSide: BorderSide(
                color: widget.dark ? Colors.white : RainCheckColors.deepSky,
              ),
            ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
        ),
        if (_message != null) ...[
          const SizedBox(height: RainCheckSpacing.sm),
          Text(_message!, style: TextStyle(color: mutedColor)),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: RainCheckSpacing.sm),
          ..._suggestions.indexed.map((entry) {
            final index = entry.$1;
            final suggestion = entry.$2;
            final isSelected = _selected?.label == suggestion.label;
            return Padding(
              padding: const EdgeInsets.only(bottom: RainCheckSpacing.xs),
              child: _SuggestionTile(
                key: Key('${widget.suggestionKeyPrefix}-$index'),
                suggestion: suggestion,
                isSelected: isSelected,
                dark: widget.dark,
                onTap: () => _selectSuggestion(suggestion),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _selected = null;
    widget.onSelected(null);

    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() {
        _suggestions = const [];
        _message =
            trimmed.isEmpty ? null : 'Type at least 3 characters to search.';
      });
      return;
    }

    setState(() {
      _message = null;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(trimmed);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _requestId++;
    _controller.clear();
    widget.onSelected(null);
    setState(() {
      _selected = null;
      _suggestions = const [];
      _message = null;
    });
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    try {
      final results = await ref
          .read(locationServiceProvider)
          .searchLocations(query);
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _suggestions = results;
        _message =
            results.isEmpty
                ? 'No matching places found. Try a city and state.'
                : null;
      });
    } on LocationServiceException catch (error) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _suggestions = const [];
        _message = error.message;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _suggestions = const [];
        _message = 'Location search failed. Try again.';
      });
    }
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    _debounce?.cancel();
    _controller.text = suggestion.label;
    setState(() {
      _selected = suggestion;
      _message = 'Selected ${suggestion.label}.';
    });
    widget.onSelected(suggestion);
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    super.key,
    required this.suggestion,
    required this.isSelected,
    required this.dark,
    required this.onTap,
  });

  final LocationSuggestion suggestion;
  final bool isSelected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        dark
            ? Colors.white.withValues(alpha: isSelected ? 0.24 : 0.12)
            : Theme.of(context).colorScheme.surface;
    final foreground = dark ? Colors.white : RainCheckColors.ink;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(RainCheckRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(RainCheckRadii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(RainCheckSpacing.sm),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.location_on_outlined,
                color: foreground,
              ),
              const SizedBox(width: RainCheckSpacing.sm),
              Expanded(
                child: Text(
                  suggestion.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
