// Copyright 2020 Kenton Hamaluik
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timecop/blocs/projects/bloc.dart';
import 'package:timecop/blocs/timers/bloc.dart';
import 'package:timecop/components/ProjectColour.dart';
import 'package:timecop/l10n.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/models/timer_entry.dart';
import 'package:timecop/screens/dashboard/components/StoppedTimerRow.dart';

import 'package:timecop/timer_utils.dart';

class GroupedStoppedTimersRow extends StatefulWidget {
  final List<TimerEntry> timers;
  const GroupedStoppedTimersRow({Key? key, required this.timers})
      : assert(timers.length > 1),
        super(key: key);

  @override
  State<GroupedStoppedTimersRow> createState() =>
      _GroupedStoppedTimersRowState();
}

class _GroupedStoppedTimersRowState extends State<GroupedStoppedTimersRow>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: -0.5);

  bool _isHovering = false;
  late bool _expanded;

  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _expanded = false;
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (_) => setState(() {
              _isHovering = true;
            }),
        onExit: (_) => setState(() {
              _isHovering = false;
            }),
        child: Slidable(
          endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.15,
              children: <Widget>[
                SlidableAction(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    icon: FontAwesomeIcons.play,
                    onPressed: (_) => _resumeTimer())
              ]),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              setState(() {
                _expanded = expanded;
                if (_expanded) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              });
            },
            leading: ProjectColour(
                project: BlocProvider.of<ProjectsBloc>(context)
                    .getProjectByID(widget.timers[0].projectID)),
            title: Text(
                TimerUtils.formatDescription(
                    context, widget.timers[0].description),
                style: TimerUtils.styleDescription(
                    context, widget.timers[0].description)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                RotationTransition(
                  turns: _iconTurns,
                  child: Icon(
                    Icons.expand_more,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                    TimerEntry.formatDuration(widget.timers.fold(
                        const Duration(),
                        (Duration sum, TimerEntry timer) =>
                            sum + timer.endTime!.difference(timer.startTime))),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
                if (_isHovering && !_expanded) const SizedBox(width: 4),
                if (_isHovering && !_expanded)
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.circlePlay),
                    onPressed: _resumeTimer,
                    tooltip: L10N.of(context).tr.resumeTimer,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
              ],
            ),
            children: widget.timers
                .map((timer) => StoppedTimerRow(timer: timer))
                .toList(),
          ),
        ));
  }

  void _resumeTimer() {
    final TimersBloc timersBloc = BlocProvider.of<TimersBloc>(context);
    final ProjectsBloc projectsBloc = BlocProvider.of<ProjectsBloc>(context);
    Project? project =
        projectsBloc.getProjectByID(widget.timers.first.projectID);
    timersBloc.add(CreateTimer(
        description: widget.timers.first.description ?? "", project: project));
  }
}
