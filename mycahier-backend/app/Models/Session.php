<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Session extends Model
{
    protected $table = 'course_sessions';

    protected $fillable = [
        'course_id',
        'date',
        'content',
        'homework',
    ];

    protected $casts = [
        'date' => 'date',
    ];

    public function course(): BelongsTo
    {
        return $this->belongsTo(Course::class, 'course_id');
    }
}