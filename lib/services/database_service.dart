import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'platform_support.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDatabase();
    return _db!;
  }

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hvac_reference_library.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE smacna_gauges (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gauge INTEGER NOT NULL,
            thickness_in REAL NOT NULL,
            thickness_mm REAL NOT NULL,
            max_dim_1in_wg TEXT NOT NULL,
            max_dim_2in_wg TEXT NOT NULL,
            max_dim_4in_wg TEXT NOT NULL,
            reinforcement_class TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE dw144_standards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            thickness_mm REAL NOT NULL,
            pressure_class TEXT NOT NULL,
            max_pressure_pa INTEGER NOT NULL,
            max_side_mm INTEGER NOT NULL,
            joint_type TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE velocity_guidelines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            application TEXT NOT NULL,
            duct_location TEXT NOT NULL,
            fpm_recommended TEXT NOT NULL,
            fpm_max TEXT NOT NULL,
            ms_recommended TEXT NOT NULL,
            ms_max TEXT NOT NULL,
            noise_criteria TEXT NOT NULL
          )
        ''');

        await _seedInitialData(db);
      },
    );
  }

  static const List<Map<String, Object?>> _gauges = [
    {
      'gauge': 26,
      'thickness_in': 0.0217,
      'thickness_mm': 0.55,
      'max_dim_1in_wg': 'Up to 12" (300 mm)',
      'max_dim_2in_wg': 'Up to 10" (250 mm)',
      'max_dim_4in_wg': 'Up to 8" (200 mm)',
      'reinforcement_class': 'Flat Drive / S-Slip (Class A)',
    },
    {
      'gauge': 24,
      'thickness_in': 0.0276,
      'thickness_mm': 0.70,
      'max_dim_1in_wg': '13" to 30" (325-750 mm)',
      'max_dim_2in_wg': '11" to 26" (275-650 mm)',
      'max_dim_4in_wg': '9" to 22" (225-550 mm)',
      'reinforcement_class': 'Standing S / Pocket Lock (Class B)',
    },
    {
      'gauge': 22,
      'thickness_in': 0.0336,
      'thickness_mm': 0.85,
      'max_dim_1in_wg': '31" to 54" (775-1350 mm)',
      'max_dim_2in_wg': '27" to 42" (675-1050 mm)',
      'max_dim_4in_wg': '23" to 36" (575-900 mm)',
      'reinforcement_class': 'Standing Seam / TDC Flange (Class C)',
    },
    {
      'gauge': 20,
      'thickness_in': 0.0396,
      'thickness_mm': 1.00,
      'max_dim_1in_wg': '55" to 84" (1375-2100 mm)',
      'max_dim_2in_wg': '43" to 60" (1075-1500 mm)',
      'max_dim_4in_wg': '37" to 50" (925-1250 mm)',
      'reinforcement_class': 'Companion Angle / TDF Flange (Class D)',
    },
  ];

  static const List<Map<String, Object?>> _dw144 = [
    {
      'thickness_mm': 0.6,
      'pressure_class': 'Class A (Low Static)',
      'max_pressure_pa': 500,
      'max_side_mm': 300,
      'joint_type': 'Flat S-Cleat / Drive Slip',
    },
    {
      'thickness_mm': 0.8,
      'pressure_class': 'Class A / B (Low & Medium Static)',
      'max_pressure_pa': 1000,
      'max_side_mm': 800,
      'joint_type': 'Mez / PDF Flange Profile',
    },
    {
      'thickness_mm': 1.0,
      'pressure_class': 'Class B / C (Medium & High Static)',
      'max_pressure_pa': 1500,
      'max_side_mm': 1250,
      'joint_type': 'Slide-on Flange with Corner Pieces',
    },
    {
      'thickness_mm': 1.2,
      'pressure_class': 'Class C / D (High Static & High Velocity)',
      'max_pressure_pa': 2000,
      'max_side_mm': 2000,
      'joint_type': 'Rolled Angle Flange & Internal Stiffener',
    },
  ];

  static const List<Map<String, Object?>> _velocities = [
    {
      'application': 'Residential',
      'duct_location': 'Main Supply Trunk',
      'fpm_recommended': '700 - 900 fpm',
      'fpm_max': '1,000 fpm',
      'ms_recommended': '3.5 - 4.5 m/s',
      'ms_max': '5.0 m/s',
      'noise_criteria': 'NC 25-30',
    },
    {
      'application': 'Commercial Office',
      'duct_location': 'Main Supply Duct',
      'fpm_recommended': '1,200 - 1,600 fpm',
      'fpm_max': '2,000 fpm',
      'ms_recommended': '6.0 - 8.0 m/s',
      'ms_max': '10.0 m/s',
      'noise_criteria': 'NC 30-35',
    },
    {
      'application': 'Industrial / High Velocity',
      'duct_location': 'Main Plant / Exhaust Shaft',
      'fpm_recommended': '2,000 - 3,000 fpm',
      'fpm_max': '3,500 fpm',
      'ms_recommended': '10.0 - 15.0 m/s',
      'ms_max': '18.0 m/s',
      'noise_criteria': 'NC 45-50',
    },
  ];

  Future<void> _seedInitialData(Database db) async {
    final batch = db.batch();
    for (final row in _gauges) {
      batch.insert('smacna_gauges', row);
    }
    for (final row in _dw144) {
      batch.insert('dw144_standards', row);
    }
    for (final row in _velocities) {
      batch.insert('velocity_guidelines', row);
    }
    await batch.commit(noResult: true);
  }

  // Web and desktop have no sqflite plugin, so serve the same data from memory.
  Future<List<Map<String, dynamic>>> getSmacnaGauges() async {
    if (!PlatformSupport.supportsSqlite) {
      return List.of(_gauges)..sort((a, b) => (b['gauge'] as int).compareTo(a['gauge'] as int));
    }
    final db = await database;
    return await db.query('smacna_gauges', orderBy: 'gauge DESC');
  }

  Future<List<Map<String, dynamic>>> getDw144Standards() async {
    if (!PlatformSupport.supportsSqlite) return List.of(_dw144);
    final db = await database;
    return await db.query('dw144_standards', orderBy: 'max_side_mm ASC');
  }

  Future<List<Map<String, dynamic>>> getVelocityGuidelines() async {
    if (!PlatformSupport.supportsSqlite) return List.of(_velocities);
    final db = await database;
    return await db.query('velocity_guidelines');
  }
}
