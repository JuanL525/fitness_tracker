import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/activity_monitor_bloc.dart';
import '../widgets/fall_confirmation_dialog.dart';

class ActivityMonitorFallListener extends StatefulWidget {
  const ActivityMonitorFallListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ActivityMonitorFallListener> createState() =>
      _ActivityMonitorFallListenerState();
}

class _ActivityMonitorFallListenerState extends State<ActivityMonitorFallListener> {
  bool _dialogVisible = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActivityMonitorBloc, ActivityMonitorState>(
      listenWhen: (previous, current) {
        if (current is FallAlertActive) {
          return previous is! FallAlertActive ||
              previous.escalated != current.escalated;
        }
        return previous is FallAlertActive;
      },
      listener: (context, state) {
        if (state is FallAlertActive) {
          if (_dialogVisible) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          _dialogVisible = true;
          showFallConfirmationDialog(
            context,
            escalated: state.escalated,
          ).whenComplete(() {
            _dialogVisible = false;
          });
          return;
        }

        if (_dialogVisible) {
          Navigator.of(context, rootNavigator: true).pop();
          _dialogVisible = false;
        }
      },
      child: widget.child,
    );
  }
}

Future<void> showFallConfirmationDialog(
  BuildContext context, {
  required bool escalated,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => FallConfirmationDialog(escalated: escalated),
  );
}
