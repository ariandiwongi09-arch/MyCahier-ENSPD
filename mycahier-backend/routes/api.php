<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CourseController;
use App\Http\Controllers\Api\SessionController;

// Inscription et connexion
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Routes accessibles uniquement aux utilisateurs connectés
Route::middleware('auth:sanctum')->group(function () {

    // Authentification
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Gestion des cours
    Route::get('/courses', [CourseController::class, 'index']);
    Route::post('/courses', [CourseController::class, 'store']);
    Route::get('/courses/{course}', [CourseController::class, 'show']);
    Route::put('/courses/{course}', [CourseController::class, 'update']);
Route::delete('/courses/{course}', [CourseController::class, 'destroy']);

    // Consultation des séances
    Route::get('/sessions', [SessionController::class, 'index']);
    Route::get('/sessions/{session}', [SessionController::class, 'show']);

    // Gestion des séances
    Route::post('/courses/{course}/sessions', [SessionController::class, 'store']);
    Route::put('/sessions/{session}', [SessionController::class, 'update']);
    Route::delete('/sessions/{session}', [SessionController::class, 'destroy']);
});