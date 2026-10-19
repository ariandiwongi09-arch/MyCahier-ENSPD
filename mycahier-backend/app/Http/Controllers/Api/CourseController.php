<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CourseController extends Controller
{
    /**
     * Afficher les cours disponibles.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role === 'teacher') {
            $courses = Course::where('teacher_id', $user->id)
                ->with('teacher')
                ->withCount('sessions')
                ->orderBy('name')
                ->get();
        } else {
            $courses = Course::with('teacher')
                ->withCount('sessions')
                ->orderBy('name')
                ->get();
        }

        return response()->json([
            'success' => true,
            'data' => $courses,
        ]);
    }

    /**
     * Afficher un cours et ses séances.
     */
    public function show(Request $request, Course $course): JsonResponse
    {
        $user = $request->user();

        if (
            $user->role === 'teacher'
            && $course->teacher_id !== $user->id
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n’êtes pas autorisé à consulter ce cours.',
            ], 403);
        }

        $course->load([
            'teacher',
            'sessions' => function ($query) {
                $query->orderByDesc('date');
            },
        ]);

        return response()->json([
            'success' => true,
            'data' => $course,
        ]);
    }

    /**
     * Créer un cours pour l'enseignant connecté.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'teacher') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les enseignants peuvent créer un cours.',
            ], 403);
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'code' => [
                'required',
                'string',
                'max:50',
                'regex:/^[A-Za-z0-9_-]+$/',
                Rule::unique('courses', 'code'),
            ],
        ], [
            'name.required' => 'Le nom du cours est obligatoire.',
            'code.required' => 'Le code du cours est obligatoire.',
            'code.unique' => 'Ce code de cours existe déjà.',
            'code.regex' => 'Le code accepte uniquement les lettres, chiffres, tirets et underscores.',
        ]);

        $course = Course::create([
            'name' => $validated['name'],
            'code' => strtoupper($validated['code']),
            'teacher_id' => $user->id,
        ]);

        $course->load('teacher');

        return response()->json([
            'success' => true,
            'message' => 'Cours créé avec succès.',
            'data' => $course,
        ], 201);
    }

    public function update(Request $request, Course $course): JsonResponse
{
    $user = $request->user();

    if ($user->role !== 'teacher') {
        return response()->json([
            'success' => false,
            'message' => 'Seuls les enseignants peuvent modifier un cours.',
        ], 403);
    }

    if ($course->teacher_id !== $user->id) {
        return response()->json([
            'success' => false,
            'message' => 'Vous ne pouvez pas modifier ce cours.',
        ], 403);
    }

    $validated = $request->validate([
        'name' => ['required', 'string', 'max:255'],
        'code' => [
            'required',
            'string',
            'max:50',
            'regex:/^[A-Za-z0-9_-]+$/',
            \Illuminate\Validation\Rule::unique('courses', 'code')
                ->ignore($course->id),
        ],
    ]);

    $course->update([
        'name' => $validated['name'],
        'code' => strtoupper($validated['code']),
    ]);

    $course->load('teacher');

    return response()->json([
        'success' => true,
        'message' => 'Cours modifié avec succès.',
        'data' => $course,
    ]);
 }
 public function destroy(Request $request, Course $course): JsonResponse
{
    $user = $request->user();

    if ($user->role !== 'teacher') {
        return response()->json([
            'success' => false,
            'message' => 'Seuls les enseignants peuvent supprimer un cours.',
        ], 403);
    }

    if ($course->teacher_id !== $user->id) {
        return response()->json([
            'success' => false,
            'message' => 'Vous ne pouvez pas supprimer ce cours.',
        ], 403);
    }

    if ($course->sessions()->exists()) {
        return response()->json([
            'success' => false,
            'message' => 'Impossible de supprimer ce cours : il contient des séances.',
        ], 422);
    }

    $course->delete();

    return response()->json([
        'success' => true,
        'message' => 'Cours supprimé avec succès.',
    ]);
 }
}