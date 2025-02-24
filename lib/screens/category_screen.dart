import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/category.dart';
import 'package:romrom_fe/screens/home_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<int> selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('카테고리를 설정하세요!'),
            Wrap(
              spacing: 6.0,
              children: Category.values.map((category) {
                final bool isSelected =
                    selectedCategories.contains(category.id);

                return ChoiceChip(
                  label: Text(category.name),
                  selected: isSelected,
                  selectedColor: Colors.blueAccent,
                  showCheckmark: false,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedCategories.add(category.id); // 선택 추가
                        debugPrint("$selectedCategories");
                      } else {
                        selectedCategories.remove(category.id); // 선택 제거
                        debugPrint("$selectedCategories");
                      }
                    });
                  },
                );
              }).toList(), // toList()로 변환
            ),
            TextButton(
              onPressed: () {
                selectedCategories.isNotEmpty
                    ? Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => const HomeScreen(),
                        ),
                      )
                    : showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('잠깐!!'),
                            content: const Text('카테고리를 선택해 주세요!'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // 다이얼로그 닫기
                                },
                                child: const Text("닫기"),
                              ),
                            ],
                          );
                        });
              },
              style: TextButton.styleFrom(backgroundColor: Colors.pink[300]),
              child: const Text('다음으로 넘어가기'),
            ),
          ],
        ),
      ),
    );
  }
}
