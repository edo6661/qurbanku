import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qurban_ku/blocs/admin/admin_bloc.dart';
import 'package:qurban_ku/blocs/admin/admin_event.dart';
import 'package:qurban_ku/services/savings_service.dart';
import 'package:qurban_ku/services/storage_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'blocs/auth/auth_state.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/peserta/peserta_dashboard_page.dart';
import 'blocs/savings/savings_bloc.dart';

class App extends StatelessWidget {
  final AuthService authService;
  final StorageService storageService;
  final SavingsService savingsService;

  const App({
    super.key,
    required this.authService,
    required this.storageService,
    required this.savingsService,
  });
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authService),
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: savingsService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authService: context.read<AuthService>())
                  ..add(AuthCheckRequested()),
          ),
          BlocProvider<SavingsBloc>(
            create: (context) =>
                SavingsBloc(savingsService: context.read<SavingsService>()),
          ),

          BlocProvider<AdminBloc>(
            create: (context) =>
                AdminBloc(savingsService: context.read<SavingsService>())
                  ..add(LoadPendingTransactions()),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tabungan Kurban',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (previous, current) {
          if (current is AuthError) return false;
          if (current is AuthLoading) return false;
          return true;
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.user.role == UserRole.admin) {
              return const AdminDashboardPage();
            } else {
              return const PesertaDashboardPage();
            }
          }

          return const LoginPage();
        },
      ),
    );
  }
}
