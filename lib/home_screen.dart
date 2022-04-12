import 'package:flutter/material.dart';

import 'item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //リストに表示させるデータ
  List<String> _unselected = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
  List<String> _selected = [];

  //左右のAnimatedListの状態（育ての親）にアクセスするためのGlobalKey
  //https://school.minpro.net/courses/1548826/lectures/35540748
  //https://api.flutter.dev/flutter/foundation/Key-class.html
  final _unselectedListKey = GlobalKey<AnimatedListState>();
  final _selectedListKey = GlobalKey<AnimatedListState>();

  int _flyingCount = 0;

  @override
  Widget build(BuildContext context) {
    print("build");
    return Scaffold(
      appBar: AppBar(
        title: Text('Two Animated List Demo'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: () => _rollback(),
      ),
      body: Row(
        children: [
          //移動前（左側）のAnimatedList
          //https://api.flutter.dev/flutter/widgets/AnimatedList-class.html
          SizedBox(
            width: 56,
            child: AnimatedList(
              key: _unselectedListKey,
              initialItemCount: _unselected.length,
              itemBuilder: (context, index, animation) {
                return InkWell(
                  onTap: () => _moveItem(
                    fromIndex: index,
                    fromList: _unselected,
                    fromKey: _unselectedListKey,
                    toList: _selected,
                    toKey: _selectedListKey,
                  ),
                  child: Item(text: _unselected[index]),
                );
              },
            ),
          ),
          //余白を埋めるWidget（Expandedみたいなもの）
          Spacer(),
          //移動後（右側）のAnimatedList
          SizedBox(
            width: 56,
            child: AnimatedList(
              key: _selectedListKey,
              initialItemCount: _selected.length,
              itemBuilder: (context, index, animation) {
                return InkWell(
                  onTap: () => _moveItem(
                    fromIndex: index,
                    fromList: _selected,
                    fromKey: _selectedListKey,
                    toList: _unselected,
                    toKey: _unselectedListKey,
                  ),
                  child: Item(text: _selected[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _moveItem({
    required int fromIndex,
    required List fromList,
    required GlobalKey<AnimatedListState> fromKey,
    required List toList,
    required GlobalKey<AnimatedListState> toKey,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    print("moveItem: $fromIndex");
    //Item（を包んでいるOpacity）のGlobalKey
    final globalKey = GlobalKey();

    //移動元のリストからタップしたItemを削除（その際データ（のリスト）とView（AnimatedList）の同期を取る必要あり）
    final item = fromList.removeAt(fromIndex);
    fromKey.currentState!.removeItem(
      fromIndex,
      (context, animation) {
        //https://api.flutter.dev/flutter/widgets/SizeTransition-class.html
        return SizeTransition(
          sizeFactor: animation,
          child: Opacity(
            key: globalKey,
            opacity: 0.0,
            child: Item(text: item),
          ),
        );
      },
      duration: duration,
    );

    _flyingCount++;

    //buildメソッド終了直後に発火されるコールバックらしい（知らなかった。。。）：Schedule a callback for the end of this frame.
    //https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addPostFrameCallback.html
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      //移動元の画面上での場所を特定
      // Find the starting position of the moving item, which is exactly the
      // gap its leaving behind, in the original list.
      final box1 = globalKey.currentContext!.findRenderObject() as RenderBox;
      final pos1 = box1.localToGlobal(Offset.zero);

      //移動先の画面での場所を特定
      // Find the destination position of the moving item, which is at the
      // end of the destination list.
      final box2 = toKey.currentContext!.findRenderObject() as RenderBox;
      final box2height = box1.size.height * (toList.length + _flyingCount - 1);
      final pos2 = box2.localToGlobal(Offset(0, box2height));

      //移動元（pos1）から移動先（pos2）に向かって300ミリ秒（duration）かけて線形移動させるアニメーション（TweenAnimation）
      //https://api.flutter.dev/flutter/widgets/TweenAnimationBuilder-class.html
      //https://docs.flutter.dev/development/ui/animations#tween-animation
      // Insert an overlay to "fly over" the item between two lists.
      final entry = OverlayEntry(builder: (BuildContext context) {
        return TweenAnimationBuilder(
          //Tweenは線形補正
          tween: Tween<Offset>(begin: pos1, end: pos2),
          duration: duration,
          builder: (_, Offset value, child) {
            return Positioned(
              left: value.dx,
              top: value.dy,
              child: Item(text: item),
            );
          },
        );
      });

      /*
      * OverLay ≒ Stackらしい
      * https://api.flutter.dev/flutter/widgets/Overlay-class.html
      *
      * The Overlay widget uses a custom stack implementation, which is very similar to the Stack widget.
      * The main use case of Overlay is related to navigation and being able to insert widgets on top of the pages in an app.
      * To simply display a stack of widgets, consider using Stack instead.
      * */
      Overlay.of(context)!.insert(entry);
      //このdurationの間に移動
      await Future.delayed(duration);
      //移動が完了したらOverLayEntryを削除
      entry.remove();
      toList.add(item);
      toKey.currentState!.insertItem(toList.length - 1);
      _flyingCount--;
    });
  }

  _rollback() {
    //リセット前のデータの要素数を取っておく（AnimatedListのリセットの際に必要）
    final _unselectedBeforeReset = _unselected;
    final _selectedBeforeReset = _selected;

    /*
    * AnimatedListもリセットしないといけない（でないとリストとの整合性がとれなくてレンジエラーになる）
    * （AnimatedListのindexはリストを操作する前のindexなので操作後はバラバラ）
    * => _selectedの方（insertする方）は上からリストの上から順番にindexがついているからいいが
    *   _unselectedの方（removeする方）は、除外されたIndexが歯抜けになっている可能性があるので注意が必要
    *   https://api.flutter.dev/flutter/widgets/AnimatedListState/removeItem.html
    * */
    //_selectedの方（insertする方）は上からリストの上から順番にindexがついているからいい
    for (int i = 0; i < _selectedBeforeReset.length; i++) {
      print("_selectedBeforeReset: $i");
      _selectedListKey.currentState!.removeItem(
        //[重要]ここは「i」ではなく「0」（removeされるたびに配列番号が繰り上がるので上から１行ずつ削除）
        //https://stackoverflow.com/a/54995346/13944817
        0,
        (context, animation) => Container(),
      );
    }
    print("end of remove _selectedBeforeReset");

    //_unselectedの方（removeする方）は、除外されたIndexが歯抜けになっている可能性があるので注意が必要
    for (int i = 0; i < _unselectedBeforeReset.length; i++) {
      _unselectedListKey.currentState!
          .removeItem(0, (context, animation) => Container());
    }

    //リストのリセット
    _unselected = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    _selected = [];
    //リセットしたリストでInsert
    for (int i = 0; i < _unselected.length; i++) {
      _unselectedListKey.currentState!.insertItem(i);
    }

    setState(() {});
  }
}
