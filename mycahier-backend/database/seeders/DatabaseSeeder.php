<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Course;
use App\Models\Session;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $teacher = User::create([
            'name' => 'Professeur ENSPD',
            'email' => 'prof@ensp.cm',
            'password' => Hash::make('password'),
            'role' => 'teacher',
        ]);

        $student = User::create([
            'name' => 'Etudiant ENSPD',
            'email' => 'student@ensp.cm',
            'password' => Hash::make('password'),
            'role' => 'student',
        ]);

        $course = Course::create([
            'name' => 'Développement Mobile',
            'code' => 'DEVMOB',
            'teacher_id' => $teacher->id,
        ]);

        Session::create([
            'course_id' => $course->id,
            'date' => now()->toDateString(),
            'content' => 'Introduction au développement d’applications mobiles avec Flutter.',
            'homework' => 'Créer une première interface Flutter.',
        ]);

        Session::create([
            'course_id' => $course->id,
            'date' => now()->subDays(2)->toDateString(),
            'content' => 'Présentation de Flutter et de l’architecture d’une application.',
            'homework' => 'Réviser les widgets Flutter.',
        ]);
    }
}