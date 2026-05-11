import 'dart:async';

import 'package:flutter/widgets.dart';

typedef StateUpdater<T> = T Function(T currentState);
typedef SelectorBuilder<TSelected> = Widget Function(
    BuildContext context, TSelected selected, Widget? child);
typedef EffectHandler<TEffect> = void Function(
    BuildContext context, TEffect effect);

abstract class ScreenController<TState, TEffect> extends ChangeNotifier {
  ScreenController(this._state);

  TState _state;
  final StreamController<TEffect> _effectController =
      StreamController<TEffect>.broadcast(sync: true);

  TState get state => _state;
  Stream<TEffect> get effects => _effectController.stream;

  @protected
  void update(StateUpdater<TState> updater) {
    final nextState = updater(_state);
    if (_state == nextState) {
      return;
    }

    _state = nextState;
    notifyListeners();
  }

  @protected
  void emit(TEffect effect) {
    if (_effectController.isClosed) {
      return;
    }
    _effectController.add(effect);
  }

  @override
  void dispose() {
    _effectController.close();
    super.dispose();
  }
}

class ControllerSelector<TController extends Listenable, TSelected>
    extends StatefulWidget {
  const ControllerSelector({
    super.key,
    required this.controller,
    required this.selector,
    required this.builder,
    this.child,
  });

  final TController controller;
  final TSelected Function(TController controller) selector;
  final SelectorBuilder<TSelected> builder;
  final Widget? child;

  @override
  State<ControllerSelector<TController, TSelected>> createState() =>
      _ControllerSelectorState<TController, TSelected>();
}

class _ControllerSelectorState<TController extends Listenable, TSelected>
    extends State<ControllerSelector<TController, TSelected>> {
  late TSelected _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selector(widget.controller);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(
    covariant ControllerSelector<TController, TSelected> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_handleControllerChanged);
    _selectedValue = widget.selector(widget.controller);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final nextValue = widget.selector(widget.controller);
    if (_selectedValue == nextValue) {
      return;
    }

    setState(() {
      _selectedValue = nextValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selectedValue, widget.child);
  }
}

class ControllerEffectListener<
    TController extends ScreenController<dynamic, TEffect>,
    TEffect> extends StatefulWidget {
  const ControllerEffectListener({
    super.key,
    required this.controller,
    required this.listener,
    required this.child,
  });

  final TController controller;
  final EffectHandler<TEffect> listener;
  final Widget child;

  @override
  State<ControllerEffectListener<TController, TEffect>> createState() =>
      _ControllerEffectListenerState<TController, TEffect>();
}

class _ControllerEffectListenerState<
    TController extends ScreenController<dynamic, TEffect>,
    TEffect> extends State<ControllerEffectListener<TController, TEffect>> {
  StreamSubscription<TEffect>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(
    covariant ControllerEffectListener<TController, TEffect> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    _subscription?.cancel();
    _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _subscription = widget.controller.effects.listen((effect) {
      if (!mounted) {
        return;
      }
      widget.listener(context, effect);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
