import 'package:flutter/material.dart';

import '../services/app_strings.dart';
import '../services/language_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageScope.of(context).service;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ----------------------------------------
        // Language heading
        // ----------------------------------------
        Row(
          children: [
            const Icon(
              Icons.language,
              size: 15,
              color: Colors.grey,
            ),
            const SizedBox(width: 7),
            Text(
              AppStrings.t(
                context,
                'language',
              ),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ----------------------------------------
        // Language buttons
        // ----------------------------------------
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: AppLanguage.values.map(
            (AppLanguage language) {
              final bool isSelected =
                  languageService.language == language;

              return ChoiceChip(
                selected: isSelected,

                label: Text(
                  language.nativeName,
                ),

                onSelected: (bool selected) {
                  if (!selected) {
                    return;
                  }

                  languageService.setLanguage(language);
                },

                selectedColor: const Color(
                  0xFF0284C7,
                ),

                backgroundColor: const Color(
                  0xFF1E293B,
                ),

                disabledColor: const Color(
                  0xFF1E293B,
                ),

                side: BorderSide.none,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),

                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Colors.grey.shade300,
                ),

                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,

                visualDensity: VisualDensity.compact,
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}