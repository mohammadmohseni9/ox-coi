/*
 * OPEN-XCHANGE legal information
 *
 * All intellectual property rights in the Software are protected by
 * international copyright laws.
 *
 *
 * In some countries OX, OX Open-Xchange and open xchange
 * as well as the corresponding Logos OX Open-Xchange and OX are registered
 * trademarks of the OX Software GmbH group of companies.
 * The use of the Logos is not covered by the Mozilla Public License 2.0 (MPL 2.0).
 * Instead, you are allowed to use these Logos according to the terms and
 * conditions of the Creative Commons License, Version 2.5, Attribution,
 * Non-commercial, ShareAlike, and the interpretation of the term
 * Non-commercial applicable to the aforementioned license is published
 * on the web site https://www.open-xchange.com/terms-and-conditions/.
 *
 * Please make sure that third-party modules and libraries are used
 * according to their respective licenses.
 *
 * Any modifications to this package must retain all copyright notices
 * of the original copyright holder(s) for the original code used.
 *
 * After any such modifications, the original and derivative code shall remain
 * under the copyright of the copyright holder(s) and/or original author(s) as stated here:
 * https://www.open-xchange.com/legal/. The contributing author shall be
 * given Attribution for the derivative code and a license granting use.
 *
 * Copyright (C) 2016-2020 OX Software GmbH
 * Mail: info@open-xchange.com
 *
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the Mozilla Public License 2.0
 * for more details.
 */

import 'dart:io';

import 'package:delta_chat_core/delta_chat_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ox_talk/source/chat/message_attachment_bloc.dart';
import 'package:ox_talk/source/chat/message_attachment_event.dart';
import 'package:ox_talk/source/chat/message_item_bloc.dart';
import 'package:ox_talk/source/chat/message_item_event.dart';
import 'package:ox_talk/source/chat/message_item_state.dart';
import 'package:ox_talk/source/widgets/avatar.dart';
import 'package:ox_talk/source/utils/conversion.dart';

class ChatMessageItem extends StatefulWidget {
  final int _chatId;
  final int _messageId;
  final bool _isGroupChat;

  ChatMessageItem(this._chatId, this._messageId, this._isGroupChat, key) : super(key: Key(key));

  @override
  _ChatMessageItemState createState() => _ChatMessageItemState();
}

class _ChatMessageItemState extends State<ChatMessageItem> with TickerProviderStateMixin {
  MessageItemBloc _messagesBloc = MessageItemBloc();
  MessageAttachmentBloc _attachmentBloc = MessageAttachmentBloc();

  @override
  void initState() {
    super.initState();
    _messagesBloc.dispatch(RequestMessage(widget._chatId, widget._messageId, widget._isGroupChat));
  }

  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: _messagesBloc,
      builder: (context, state) {
        if (state is MessageItemStateSuccess) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: state.messageIsOutgoing
                ? buildSentMessage(state)
                : buildReceivedMessage(
                    widget._isGroupChat,
                    state,
                  ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget buildSentMessage(MessageItemStateSuccess state) {
    String text = state.messageText;
    String time = state.messageTimestamp;
    bool hasFile = state.hasFile;
    return FractionallySizedBox(
        alignment: Alignment.topRight,
        widthFactor: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              decoration: buildBoxDecoration(Colors.blue[50]),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: hasFile ? buildAttachmentMessage(state.attachmentWrapper, time) : buildTextMessage(text, time),
              ),
            ),
          ],
        ));
  }

  BoxDecoration buildBoxDecoration(Color color) {
    return BoxDecoration(
        shape: BoxShape.rectangle,
        boxShadow: [
          new BoxShadow(
            color: Colors.grey,
            blurRadius: 2.0,
          ),
        ],
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(8.0)));
  }

  Widget buildAttachmentMessage(AttachmentWrapper attachment, String time) {
    return GestureDetector(
      onTap: _openAttachment,
      child: attachment.type == ChatMsg.typeImage ? buildImageAttachmentMessage(attachment, time) : buildGenericAttachmentMessage(attachment, time),
    );
  }

  Row buildGenericAttachmentMessage(AttachmentWrapper attachment, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.attach_file,
          size: 30.0,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(attachment.filename),
            Text(byteToPrintableSize(attachment.size)),
          ],
        ),
        Padding(padding: EdgeInsets.only(left: 8.0)),
        buildTime(time),
      ],
    );
  }

  Widget buildImageAttachmentMessage(AttachmentWrapper attachment, String time) {
    File file = File(attachment.path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.file(file),
        Padding(padding: EdgeInsets.only(top: 4.0)),
        buildTime(time),
      ],
    );
  }

  Widget buildTextMessage(String text, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(text),
        ),
        Padding(padding: EdgeInsets.only(left: 8.0)),
        buildTime(time),
      ],
    );
  }

  StatelessWidget buildTime(String time) {
    return Text(time,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 12,
        ));
  }

  Widget buildReceivedMessage(bool isGroupChat, MessageItemStateSuccess state) {
    String name = state.contactName;
    String email = state.contactAddress;
    String text = state.messageText;
    Color color = state.contactColor;
    String time = state.messageTimestamp;
    bool hasFile = state.hasFile;
    return FractionallySizedBox(
      alignment: Alignment.topLeft,
      widthFactor: 0.8,
      child: Row(
        children: <Widget>[
          isGroupChat
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Avatar(
                    initials: getInitials(name, email),
                    color: color,
                  ),
                )
              : Container(),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: buildBoxDecoration(Colors.white),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  isGroupChat
                      ? Text(
                          name,
                          style: TextStyle(color: color),
                        )
                      : Container(
                          constraints: BoxConstraints(maxWidth: 0.0),
                        ),
                  hasFile ? buildAttachmentMessage(state.attachmentWrapper, time) : buildTextMessage(text, time),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getInitials(String name, String email) {
    if (name != null && name.isNotEmpty) {
      return name.substring(0, 1);
    }
    if (email != null && email.isNotEmpty) {
      return email.substring(0, 1);
    }
    return "";
  }

  void _openAttachment() {
    _attachmentBloc.dispatch(RequestAttachment(widget._chatId, widget._messageId));
  }
}
