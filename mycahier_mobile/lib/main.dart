import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyCahierApp());
}

class AppConfig {
  static const String apiUrl = 'http://127.0.0.1:8000/api';
}

class MyCahierApp extends StatelessWidget {
  const MyCahierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCahier ENSPD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF17365D),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E6EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================
// SERVICE API
// ============================================================

class ApiService {
  static Map<String, String> _headers({String? token}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception('Le serveur a renvoyé une réponse illisible.');
    }
  }

  static String _extractError(dynamic decoded, String fallback) {
    if (decoded is Map) {
      if (decoded['message'] != null) {
        final message = decoded['message'].toString();

        if (decoded['errors'] is Map) {
          final errors = decoded['errors'] as Map;

          if (errors.isNotEmpty) {
            final firstError = errors.values.first;

            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
          }
        }

        return message;
      }

      if (decoded['errors'] is Map) {
        final errors = decoded['errors'] as Map;

        if (errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
      }
    }

    return fallback;
  }

  static void _checkSuccess(
    http.Response response,
    dynamic decoded,
    String fallback,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(decoded, fallback));
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final decoded = _decodeResponse(response);

    _checkSuccess(response, decoded, 'Connexion impossible.');

    if (decoded is! Map) {
      throw Exception('Réponse de connexion invalide.');
    }

    final result = Map<String, dynamic>.from(decoded);

    if (result['data'] is Map) {
      result.addAll(Map<String, dynamic>.from(result['data'] as Map));
    }

    if (result['token'] == null || result['user'] is! Map) {
      throw Exception(
        'La réponse ne contient pas les informations de connexion attendues.',
      );
    }

    return result;
  }

  static Future<List<dynamic>> getCourses(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiUrl}/courses'),
      headers: _headers(token: token),
    );

    final decoded = _decodeResponse(response);

    _checkSuccess(response, decoded, 'Impossible de charger les cours.');

    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map) {
      if (decoded['data'] is List) {
        return List<dynamic>.from(decoded['data']);
      }

      if (decoded['courses'] is List) {
        return List<dynamic>.from(decoded['courses']);
      }
    }

    return [];
  }

  static Future<List<dynamic>> getSessions(
    String token,
    int courseId, {
    String? search,
    String? date,
  }) async {
    final queryParameters = <String, String>{'course_id': courseId.toString()};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (date != null && date.trim().isNotEmpty) {
      queryParameters['date'] = date.trim();
    }

    final uri = Uri.parse('${AppConfig.apiUrl}/sessions')
        .replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: _headers(token: token));

    final decoded = _decodeResponse(response);

    _checkSuccess(response, decoded, 'Impossible de charger les séances.');

    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map && decoded['data'] is List) {
      return List<dynamic>.from(decoded['data']);
    }

    if (decoded is Map && decoded['sessions'] is List) {
      return List<dynamic>.from(decoded['sessions']);
    }

    return [];
  }

  static Future<void> createCourse({
    required String token,
    required String name,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/courses'),
      headers: _headers(token: token),
      body: jsonEncode({
        'name': name.trim(),
        'code': code.trim().toUpperCase(),
      }),
    );

    final decoded = _decodeResponse(response);

    _checkSuccess(response, decoded, 'Impossible de créer le cours.');
  }

  static Future<void> deleteCourse({
    required String token,
    required int courseId,
  }) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiUrl}/courses/$courseId'),
      headers: _headers(token: token),
    );

    final decoded = _decodeResponse(response);

    _checkSuccess(response, decoded, 'Impossible de supprimer le cours.');
  }

  static Future<void> updateCourse({
    required String token,
    required int courseId,
    required String name,
    required String code,
  }) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiUrl}/courses/$courseId'),
      headers: _headers(token: token),
      body: jsonEncode({
        'name': name.trim(),
        'code': code.trim().toUpperCase(),
      }),
    );

    final decoded = _decodeResponse(response);

    _checkSuccess(response, decoded, 'Impossible de modifier le cours.');
  }

  static Future<void> createSession({
    required String token,
    required int courseId,
    required String date,
    required String content,
    required String homework,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/courses/$courseId/sessions'),
      headers: _headers(token: token),
      body: jsonEncode({
        'date': date,
        'content': content,
        'homework': homework.isEmpty ? null : homework,
      }),
    );

    final decoded = _decodeResponse(response);

    _checkSuccess(response, decoded, 'Impossible de créer la séance.');
  }

  static Future<void> updateSession({
    required String token,
    required int sessionId,
    required String date,
    required String content,
    required String homework,
  }) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiUrl}/sessions/$sessionId'),
      headers: _headers(token: token),
      body: jsonEncode({
        'date': date,
        'content': content,
        'homework': homework.isEmpty ? null : homework,
      }),
    );

    final decoded = _decodeResponse(response);

    _checkSuccess(response, decoded, 'Impossible de modifier la séance.');
  }

  static Future<void> deleteSession({
    required String token,
    required int sessionId,
  }) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiUrl}/sessions/$sessionId'),
      headers: _headers(token: token),
    );

    final decoded = _decodeResponse(response);

    _checkSuccess(response, decoded, 'Impossible de supprimer la séance.');
  }

  static Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/logout'),
      headers: _headers(token: token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('La déconnexion auprès du serveur a échoué.');
    }
  }
}

// ============================================================
// PAGE DE CONNEXION
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _loading) {
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      final user = Map<String, dynamic>.from(result['user'] as Map);
      final token = result['token'].toString();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardPage(token: token, user: user),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 76,
                          width: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FF),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 42,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'MyCahier ENSPD',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF17365D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Votre cahier de texte numérique.',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Bienvenue !',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connectez-vous pour consulter vos cours.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez saisir votre adresse e-mail.';
                            }

                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(value.trim())) {
                              return 'Veuillez saisir une adresse e-mail valide.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez saisir votre mot de passe.';
                            }

                            return null;
                          },
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: _loading ? null : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 23,
                                    width: 23,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ENSPD • Plateforme académique',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TABLEAU DE BORD
// ============================================================

class DashboardPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const DashboardPage({super.key, required this.token, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<dynamic>> _coursesFuture;

  bool get _isTeacher =>
      widget.user['role']?.toString().toLowerCase() == 'teacher';

  String get _userName =>
      widget.user['name']?.toString() ?? 'Utilisateur ENSPD';

  String get _userRole {
    if (_isTeacher) return 'Enseignant';

    if (widget.user['role']?.toString().toLowerCase() == 'student') {
      return 'Étudiant';
    }

    return 'Membre ENSPD';
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() {
    _coursesFuture = ApiService.getCourses(widget.token);
  }

  Future<void> _logout() async {
    try {
      await ApiService.logout(widget.token);
    } catch (_) {
      // La déconnexion locale reste possible si le serveur est indisponible.
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _openCourse(Map<String, dynamic> course) async {
    if (course['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant du cours introuvable.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionsPage(
          token: widget.token,
          course: course,
          isTeacher: _isTeacher,
        ),
      ),
    );

    if (mounted) {
      setState(_loadCourses);
    }
  }

  Future<void> _createCourse() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    bool loading = false;
    String? errorMessage;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: Color(0xFF1565C0)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Nouveau cours')),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        enabled: !loading,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nom du cours',
                          hintText: 'Ex. Développement Web',
                          prefixIcon: const Icon(Icons.book_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom du cours est obligatoire.';
                          }

                          if (value.trim().length > 255) {
                            return 'Le nom est trop long.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: codeController,
                        enabled: !loading,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Code du cours',
                          hintText: 'Ex. DEVWEB',
                          prefixIcon: const Icon(Icons.tag_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          final code = value?.trim() ?? '';

                          if (code.isEmpty) {
                            return 'Le code du cours est obligatoire.';
                          }

                          if (!RegExp(r'^[A-Za-z0-9_-]{1,50}$')
                              .hasMatch(code)) {
                            return 'Utilisez lettres, chiffres, - ou _.';
                          }

                          return null;
                        },
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            loading = true;
                            errorMessage = null;
                          });

                          try {
                            await ApiService.createCourse(
                              token: widget.token,
                              name: nameController.text,
                              code: codeController.text,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.of(dialogContext).pop(true);
                          } catch (error) {
                            setDialogState(() {
                              loading = false;
                              errorMessage = error.toString().replaceFirst(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                        },
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(loading ? 'Création...' : 'Créer le cours'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();

    if (created == true && mounted) {
      setState(_loadCourses);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cours créé avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editCourse(Map<String, dynamic> course) async {
    final courseId = int.tryParse(course['id'].toString());

    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant du cours invalide.')),
      );
      return;
    }

    final nameController = TextEditingController(
      text: course['name']?.toString() ?? '',
    );

    final codeController = TextEditingController(
      text: course['code']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifier le cours'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom du cours'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Code du cours'),
                  validator: (value) {
                    final code = value?.trim() ?? '';
                    if (!RegExp(r'^[A-Za-z0-9_-]{1,50}$').hasMatch(code)) {
                      return 'Code invalide.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (updated == true) {
      try {
        await ApiService.updateCourse(
          token: widget.token,
          courseId: courseId,
          name: nameController.text,
          code: codeController.text,
        );

        if (!mounted) return;

        setState(_loadCourses);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours modifié avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    nameController.dispose();
    codeController.dispose();
  }

  Future<void> _deleteCourse(Map<String, dynamic> course) async {
    final courseId = int.tryParse(course['id'].toString());

    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant du cours invalide.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le cours'),
          content: Text('Voulez-vous vraiment supprimer "${course['name']}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteCourse(token: widget.token, courseId: courseId);

      if (!mounted) return;

      setState(_loadCourses);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cours supprimé avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyCahier ENSPD',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_loadCourses);
          await _coursesFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Bienvenue !',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userRole,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Mes cours',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF17365D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isTeacher
                  ? 'Sélectionnez un cours pour gérer ses séances.'
                  : 'Sélectionnez un cours pour consulter ses séances.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),

            if (_isTeacher) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createCourse,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Ajouter un cours'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            FutureBuilder<List<dynamic>>(
              future: _coursesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return _StatusCard(
                    icon: Icons.cloud_off_outlined,
                    title: 'Chargement impossible',
                    message: snapshot.error.toString().replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    buttonLabel: 'Réessayer',
                    onPressed: () {
                      setState(_loadCourses);
                    },
                  );
                }

                final courses = snapshot.data ?? [];

                if (courses.isEmpty) {
                  return const _StatusCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Aucun cours disponible',
                    message: 'Aucun cours n’est actuellement associé à votre compte.',
                  );
                }

                return Column(
                  children: courses.map((item) {
                    final course = Map<String, dynamic>.from(item as Map);

                    final teacherData = course['teacher'];

                    String teacherName = 'Enseignant non renseigné';

                    if (teacherData is Map && teacherData['name'] != null) {
                      teacherName = teacherData['name'].toString();
                    }

                    final courseName =
                        course['name']?.toString() ?? 'Cours sans nom';

                    final courseCode =
                        course['code']?.toString() ?? 'Sans code';

                    final sessionsCount =
                        course['sessions_count']?.toString() ?? '0';

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Color(0xFFE6EAF0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => _openCourse(course),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    height: 58,
                                    width: 58,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F1FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      size: 30,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          courseName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF17365D),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text('Code : $courseCode'),
                                        const SizedBox(height: 5),
                                        Text(
                                          teacherName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.event_note_outlined,
                                              size: 16,
                                              color: Color(0xFF1565C0),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '$sessionsCount séance(s)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF1565C0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF1565C0),
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_isTeacher) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _editCourse(course),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Modifier'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _deleteCourse(course),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                      label: const Text('Supprimer'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'MyCahier ENSPD • Votre suivi académique',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LISTE DES SÉANCES
// ============================================================

class SessionsPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> course;
  final bool isTeacher;

  const SessionsPage({
    super.key,
    required this.token,
    required this.course,
    required this.isTeacher,
  });

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  late Future<List<dynamic>> _sessionsFuture;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  DateTime? _selectedFilterDate;

  int get _courseId => int.parse(widget.course['id'].toString());

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty || _selectedFilterDate != null;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _dateForApi(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _dateForDisplay(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _loadSessions() {
    _sessionsFuture = ApiService.getSessions(
      widget.token,
      _courseId,
      search: _searchController.text.trim(),
      date: _selectedFilterDate == null
          ? null
          : _dateForApi(_selectedFilterDate!),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(_loadSessions);
    });
  }

  Future<void> _chooseFilterDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Filtrer par date de séance',
      cancelText: 'Annuler',
      confirmText: 'Filtrer',
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedFilterDate = picked;
        _loadSessions();
      });
    }
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedFilterDate = null;
      _loadSessions();
    });
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Date non renseignée';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _openSessionForm({Map<String, dynamic>? session}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionFormPage(
          token: widget.token,
          courseId: _courseId,
          session: session,
        ),
      ),
    );

    if (saved == true && mounted) {
      setState(_loadSessions);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session == null
                ? 'Séance ajoutée avec succès.'
                : 'Séance modifiée avec succès.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _deleteSession(Map<String, dynamic> session) async {
    final sessionId = int.tryParse(session['id'].toString());

    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant de séance invalide.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la séance ?'),
          content: const Text(
            'Cette action est définitive. '
            'Voulez-vous vraiment supprimer cette séance ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.deleteSession(token: widget.token, sessionId: sessionId);

      if (!mounted) return;

      setState(_loadSessions);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Séance supprimée avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final date = _formatDate(session['date']);
    final content = session['content']?.toString().trim() ?? '';
    final homework = session['homework']?.toString().trim() ?? '';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE6EAF0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF1565C0),
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Séance de cours',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17365D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isTeacher)
                  PopupMenuButton<String>(
                    tooltip: 'Actions sur la séance',
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openSessionForm(session: session);
                      } else if (value == 'delete') {
                        _deleteSession(session);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 10),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.menu_book_outlined, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Contenu du cours',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content.isEmpty ? 'Aucun contenu renseigné.' : content,
              style: const TextStyle(height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 22),
            const Row(
              children: [
                Icon(Icons.assignment_outlined, color: Color(0xFFEF8C00)),
                SizedBox(width: 8),
                Text(
                  'Travail à faire',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                homework.isEmpty
                    ? 'Aucun travail à faire renseigné.'
                    : homework,
                style: const TextStyle(height: 1.6, color: Color(0xFF704800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseName = widget.course['name']?.toString() ?? 'Cours';

    final courseCode = widget.course['code']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Séances du cours',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: widget.isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => _openSessionForm(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une séance'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_loadSessions);
          await _sessionsFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    courseName,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code : $courseCode',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.isTeacher
                        ? 'Gérez les séances et les travaux à réaliser.'
                        : 'Consultez le contenu des cours et les travaux à réaliser.',
                    style: const TextStyle(color: Colors.white, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Historique des séances',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF17365D),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher dans le contenu des séances...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer la recherche',
                        onPressed: () {
                          _searchDebounce?.cancel();
                          _searchController.clear();
                          setState(_loadSessions);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _chooseFilterDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _selectedFilterDate == null
                        ? 'Filtrer par date'
                        : _dateForDisplay(_selectedFilterDate!),
                  ),
                ),
                if (_hasActiveFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Effacer les filtres'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: _sessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return _StatusCard(
                    icon: Icons.cloud_off_outlined,
                    title: 'Chargement impossible',
                    message: snapshot.error.toString().replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    buttonLabel: 'Réessayer',
                    onPressed: () {
                      setState(_loadSessions);
                    },
                  );
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  return _StatusCard(
                    icon: Icons.event_busy_outlined,
                    title: _hasActiveFilters
                        ? 'Aucun résultat'
                        : 'Aucune séance enregistrée',
                    message: _hasActiveFilters
                        ? 'Aucune séance ne correspond à votre recherche ou à la date sélectionnée. Essayez de modifier ou d’effacer les filtres.'
                        : widget.isTeacher
                        ? 'Ajoutez la première séance de ce cours.'
                        : 'Ce cours ne possède pas encore de séance disponible.',
                    buttonLabel: _hasActiveFilters
                        ? 'Effacer les filtres'
                        : null,
                    onPressed: _hasActiveFilters ? _clearFilters : null,
                  );
                }

                return Column(
                  children: sessions.map((item) {
                    final session = Map<String, dynamic>.from(item as Map);

                    return _buildSessionCard(session);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FORMULAIRE D'AJOUT ET DE MODIFICATION
// ============================================================

class SessionFormPage extends StatefulWidget {
  final String token;
  final int courseId;
  final Map<String, dynamic>? session;

  const SessionFormPage({
    super.key,
    required this.token,
    required this.courseId,
    this.session,
  });

  @override
  State<SessionFormPage> createState() => _SessionFormPageState();
}

class _SessionFormPageState extends State<SessionFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _contentController = TextEditingController();
  final _homeworkController = TextEditingController();

  DateTime? _selectedDate;
  bool _saving = false;

  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();

    final session = widget.session;

    if (session != null) {
      final rawDate = session['date']?.toString();

      if (rawDate != null) {
        _selectedDate = DateTime.tryParse(rawDate);
      }

      _contentController.text = session['content']?.toString() ?? '';

      _homeworkController.text = session['homework']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _homeworkController.dispose();
    super.dispose();
  }

  String _dateForApi(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _dateForDisplay(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();

    final initialDate = _selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Choisir la date de la séance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveSession() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir la date de la séance.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final date = _dateForApi(_selectedDate!);
      final content = _contentController.text.trim();
      final homework = _homeworkController.text.trim();

      if (_isEditing) {
        final sessionId = int.tryParse(widget.session!['id'].toString());

        if (sessionId == null) {
          throw Exception('Identifiant de séance invalide.');
        }

        await ApiService.updateSession(
          token: widget.token,
          sessionId: sessionId,
          date: date,
          content: content,
          homework: homework,
        );
      } else {
        await ApiService.createSession(
          token: widget.token,
          courseId: widget.courseId,
          date: date,
          content: content,
          homework: homework,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier la séance' : 'Nouvelle séance',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_calendar_outlined,
                    color: Color(0xFF1565C0),
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Modifiez les informations de cette séance.'
                          : 'Renseignez les informations de la nouvelle séance.',
                      style: const TextStyle(
                        color: Color(0xFF17365D),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Date de la séance *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _saving ? null : _chooseDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE0E6EF)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Sélectionner une date'
                                  : _dateForDisplay(_selectedDate!),
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? Colors.black54
                                    : const Color(0xFF17365D),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Contenu du cours *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _contentController,
                    enabled: !_saving,
                    minLines: 4,
                    maxLines: 7,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Décrivez le contenu de la séance...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 65),
                        child: Icon(Icons.menu_book_outlined),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le contenu du cours est obligatoire.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Travail à faire',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _homeworkController,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Indiquez les exercices ou devoirs...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 45),
                        child: Icon(Icons.assignment_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _saveSession,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isEditing
                                  ? Icons.save_outlined
                                  : Icons.add_circle_outline,
                            ),
                      label: Text(
                        _saving
                            ? 'Enregistrement...'
                            : _isEditing
                            ? 'Enregistrer les modifications'
                            : 'Ajouter la séance',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CARTE DES ÉTATS : CHARGEMENT, ERREUR OU ABSENCE DE DONNÉES
// ============================================================

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF1565C0)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17365D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
