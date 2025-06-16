import 'package:shadcn_flutter/shadcn_flutter.dart';

class DialogExample1 extends StatelessWidget {
  const DialogExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            final FormController controller = FormController();
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: AlertDialog(
                dismissKeyboardOnTapOutside: true,
                title: const Text('Edit profile'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 400,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            'Make changes to your profile here. Click save when you\'re done'),
                        const Gap(16),
                        Form(
                          controller: controller,
                          child: FormTableLayout(rows: [
                            FormField<String>(
                              key: FormKey(#name),
                              label: Text('Name'),
                              child: TextField(
                                initialValue: 'Thito Yalasatria Sunarya',
                              ),
                            ),
                            FormField<String>(
                              key: FormKey(#username),
                              label: Text('Username'),
                              child: TextField(
                                initialValue: '@sunaryathito',
                              ),
                            ),
                            FormField<String>(
                              key: FormKey(#email),
                              label: Text('Email'),
                              child: TextField(
                                initialValue: 'thito@example.com',
                              ),
                            ),
                            FormField<String>(
                              key: FormKey(#bio),
                              label: Text('Bio'),
                              child: TextField(
                                initialValue: 'I love coding!',
                                maxLines: 3,
                              ),
                            ),
                          ]),
                        ).withPadding(vertical: 16),
                      ],
                    ),
                  ),
                ),
                actions: [
                  PrimaryButton(
                    child: const Text('Save changes'),
                    onPressed: () {
                      Navigator.of(context).pop(controller.values);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const Text('Edit Profile'),
    );
  }
}
