<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\Session;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SessionController extends Controller
{
       /**
     * Consulter, rechercher et filtrer les séances.
     */
    public function index(Request $request): JsonResponse
{
    $user = $request->user();

    if (!in_array($user->role, ['teacher', 'student'], true)) {
        return response()->json([
            'success' => false,
            'message' => 'Accès non autorisé.',
        ], 403);
    }

    $query = Session::with(['course.teacher']);

    // Un enseignant consulte uniquement les séances de ses cours.
    if ($user->role === 'teacher') {
        $query->whereHas('course', function ($courseQuery) use ($user) {
            $courseQuery->where('teacher_id', $user->id);
        });
    }
        // Filtrer par cours.
        if ($request->filled('course_id')) {
            $query->where('course_id', $request->query('course_id'));
        }

        // Rechercher dans le contenu, les devoirs et le cours.
        if ($request->filled('search')) {
            $search = $request->query('search');

            $query->where(function ($subQuery) use ($search) {
                $subQuery->where('content', 'like', '%' . $search . '%')
                    ->orWhere('homework', 'like', '%' . $search . '%')
                    ->orWhereHas('course', function ($courseQuery) use ($search) {
                        $courseQuery->where('name', 'like', '%' . $search . '%')
                            ->orWhere('code', 'like', '%' . $search . '%');
                    });
            });
        }

        // Filtrer par date précise.
        if ($request->filled('date')) {
            $request->validate([
                'date' => ['date'],
            ]);

            $query->whereDate('date', $request->query('date'));
        }

        // Trier du plus récent au plus ancien.
        $sessions = $query->orderByDesc('date')->get();

        return response()->json([
            'success' => true,
            'total' => $sessions->count(),
            'data' => $sessions,
        ]);
    }

    /**
     * Consulter une session précise.
     */
    public function show(Request $request, Session $session): JsonResponse
{
    $user = $request->user();

    if (!in_array($user->role, ['teacher', 'student'], true)) {
        return response()->json([
            'success' => false,
            'message' => 'Accès non autorisé.',
        ], 403);
    }

    $session->load('course');

    // Un enseignant ne consulte que les séances de ses propres cours.
    if (
        $user->role === 'teacher' &&
        (
            !$session->course ||
            (int) $session->course->teacher_id !== (int) $user->id
        )
    ) {
        return response()->json([
            'success' => false,
            'message' => 'Vous n’êtes pas autorisé à consulter cette séance.',
        ], 403);
    }

    $session->load(['course.teacher']);

    return response()->json([
        'success' => true,
        'data' => $session,
    ]);
}

    /**
     * Créer une session pour un cours appartenant au professeur.
     */
    public function store(Request $request, Course $course): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'teacher') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les enseignants peuvent créer une session.',
            ], 403);
        }

        if ((int) $course->teacher_id !== (int) $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n’êtes pas autorisé à ajouter une session à ce cours.',
            ], 403);
        }

        $validated = $request->validate([
            'date' => ['required', 'date'],
            'content' => ['required', 'string'],
            'homework' => ['nullable', 'string'],
        ]);

        $session = Session::create([
            'course_id' => $course->id,
            'date' => $validated['date'],
            'content' => $validated['content'],
            'homework' => $validated['homework'] ?? null,
        ]);

        $session->load(['course.teacher']);

        return response()->json([
            'success' => true,
            'message' => 'Session créée avec succès.',
            'data' => $session,
        ], 201);
    }

    /**
     * Modifier une session appartenant au professeur connecté.
     */
    public function update(Request $request, Session $session): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'teacher') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les enseignants peuvent modifier une session.',
            ], 403);
        }

        $session->load('course');

        if (
            !$session->course ||
            (int) $session->course->teacher_id !== (int) $user->id
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n’êtes pas autorisé à modifier cette session.',
            ], 403);
        }

        $validated = $request->validate([
            'date' => ['sometimes', 'required', 'date'],
            'content' => ['sometimes', 'required', 'string'],
            'homework' => ['sometimes', 'nullable', 'string'],
        ]);

        $session->update($validated);
        $session->load(['course.teacher']);

        return response()->json([
            'success' => true,
            'message' => 'Session modifiée avec succès.',
            'data' => $session,
        ]);
    }

    /**
     * Supprimer une session appartenant au professeur connecté.
     */
    public function destroy(Request $request, Session $session): JsonResponse
    {
        $user = $request->user();

        if ($user->role !== 'teacher') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les enseignants peuvent supprimer une session.',
            ], 403);
        }

        $session->load('course');

        if (
            !$session->course ||
            (int) $session->course->teacher_id !== (int) $user->id
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n’êtes pas autorisé à supprimer cette session.',
            ], 403);
        }

        $session->delete();

        return response()->json([
            'success' => true,
            'message' => 'Session supprimée avec succès.',
        ]);
    }
}