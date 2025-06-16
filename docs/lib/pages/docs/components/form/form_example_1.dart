import 'dart:convert';

import 'package:shadcn_flutter/shadcn_flutter.dart';

class FormExample1 extends StatefulWidget {
  const FormExample1({super.key});

  @override
  State<FormExample1> createState() => _FormExample1State();
}

class _FormExample1State extends State<FormExample1> {
  final _usernameKey = const FormKey<String>('username');
  final _passwordKey = const FormKey<String>('password');
  final _confirmPasswordKey = const FormKey<String>('confirmPassword');
  final _fruitKey = const FormKey<String>('fruit');
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: Form(
        onSubmit: (context, values) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Form Values'),
                content: Text(jsonEncode(values.map(
                  (key, value) => MapEntry(key.key, value),
                ))),
                actions: [
                  PrimaryButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FormTableLayout(
              rows: [
                FormField<String>(
                  key: _usernameKey,
                  label: const Text('Username'),
                  hint: const Text('This is your public display name'),
                  validator: const LengthValidator(min: 4),
                  child: const TextField(
                    initialValue: 'sunarya-thito',
                  ),
                ),
                FormField<String>(
                  key: _passwordKey,
                  label: const Text('Password'),
                  validator: const LengthValidator(min: 8),
                  child: const TextField(
                    obscureText: true,
                  ),
                ),
                FormField<String>(
                  key: _confirmPasswordKey,
                  label: const Text('Confirm Password'),
                  validator: CompareWith.equal(_passwordKey,
                      message: 'Passwords do not match'),
                  child: const TextField(
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const Gap(16),
            PrimaryButton(
              child: const Text('Submit'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Form Values'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Form submitted'),
                        FormField<String>(
                          key: _fruitKey,
                          label: const Text('Fruit'),
                          child: Select<String>(
                            overlayHandler: const PopoverOverlayHandler(),
                            popoverContext: context,
                            children: [
                              SelectGroup(
                                headers: [SelectLabel(child: Text('Fruits'))],
                                children: [
                                  SelectItemButton(
                                    value: 'Apple',
                                    child: Text('Apple'),
                                  ),
                                ],
                              ),
                            ],
                            value: selectedValue,
                            onChanged: (value) {
                              setState(() {
                                selectedValue = value;
                              });
                            },
                            itemBuilder: (context, item) => Text(item),
                            searchFilter: (item, query) {
                              return item
                                      .toLowerCase()
                                      .contains(query.toLowerCase())
                                  ? 1
                                  : 0;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fruit').textSmall(),
                const Gap(8),
                Select<String>(
                  value: selectedValue,
                  onChanged: (value) {
                    setState(() {
                      selectedValue = value;
                    });
                  },
                  itemBuilder: (context, item) => Text(item),
                  searchFilter: (item, query) {
                    return item.toLowerCase().contains(query.toLowerCase())
                        ? 1
                        : 0;
                  },
                  placeholder: const Text('Select a fruit'),
                  children: const [
                    SelectGroup(
                      headers: [SelectLabel(child: Text('Fruits'))],
                      children: [
                        SelectItemButton(
                          value: 'Apple',
                          child: Text('Apple'),
                        ),
                        SelectItemButton(
                          value: 'Banana',
                          child: Text('Banana'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (selectedValue == null || selectedValue!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Text(
                          'Please select a fruit',
                          style: theme.typography.xSmall.copyWith(
                            color: theme.colorScheme.destructive,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const Gap(24),
            FormErrorBuilder(
              builder: (context, errors, child) {
                bool isSelectValid =
                    selectedValue != null && selectedValue!.isNotEmpty;

                return PrimaryButton(
                  onPressed: (errors.isEmpty && isSelectValid)
                      ? () => context.submitForm()
                      : null,
                  child: const Text('Submit'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
