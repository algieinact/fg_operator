<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthApiController;
use App\Http\Controllers\Api\OperatorApiController;

// Public API Auth
Route::post('/auth/login', [AuthApiController::class, 'login']);

// Protected API routes dengan custom middleware (no session)
Route::middleware('api.auth')->group(function () {
    
    // Simple debug routes
    Route::get('/debug/simple', function (Request $request) {
        $user = $request->user();
        return response()->json([
            'success' => true,
            'message' => 'Custom API auth works!',
            'user_id' => $user ? $user->id : null,
            'username' => $user ? $user->username : null,
            'user_name' => $user ? $user->name : null,
        ]);
    });

    Route::get('/debug/token', function (Request $request) {
        $user = $request->user();
        return response()->json([
            'success' => true,
            'message' => 'Token authentication works!',
            'user_id' => $user->id,
            'username' => $user->username,
            'name' => $user->name,
        ]);
    });

    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::get('/auth/me', [AuthApiController::class, 'me']);
    Route::post('/auth/logout', [AuthApiController::class, 'logout']);

    // Test route untuk debugging
    Route::get('/test/auth', function (Request $request) {
        $user = $request->user();
        return response()->json([
            'success' => true,
            'message' => 'Authentication successful',
            'user' => [
                'id' => $user->id,
                'username' => $user->username,
                'name' => $user->name,
                'role_id' => $user->role_id,
                'has_role_relationship' => method_exists($user, 'role'),
                'role_loaded' => $user->relationLoaded('role'),
            ]
        ]);
    });

    // Use API role middleware to avoid web guard redirects
    Route::middleware('api.role:admin')->group(function () {
        Route::get('/admin/ping', function () {
            return ['ok' => true, 'scope' => 'admin'];
        });
    });

    Route::middleware('api.role:operator')->group(function () {
        Route::get('/operator/ping', function () {
            return ['ok' => true, 'scope' => 'operator'];
        });

        // Test route untuk debugging role operator
        Route::get('/operator/test', function (Request $request) {
            $user = $request->user();
            $role = $user->role;
            
            return response()->json([
                'success' => true,
                'message' => 'Operator role check successful',
                'user' => [
                    'id' => $user->id,
                    'username' => $user->username,
                    'name' => $user->name,
                    'role_id' => $user->role_id,
                    'role_name' => $role ? $role->role_name : 'No role found',
                    'role_loaded' => $user->relationLoaded('role'),
                ]
            ]);
        });

        // Operator Dashboard
        Route::get('/operator/dashboard', [OperatorApiController::class, 'dashboard']);

        // ===== POSTING OPERATIONS (Store) =====
        // NEW: Scan slot name for posting (matches web controller)
        Route::post('/operator/posting/scan-slot', [OperatorApiController::class, 'scanSlotnameForPosting']);
        
        // UPDATED: Store by ERP with new logic (matches web controller)
        Route::post('/operator/posting/store-by-erp', [OperatorApiController::class, 'storeByErp']);

        // ===== PULLING OPERATIONS =====
        // Scan slot for pulling (updated logic)
        Route::post('/operator/pulling/scan-slot', [OperatorApiController::class, 'scanSlotForPull']);
        
        // Pull by lot number (updated logic)
        Route::post('/operator/pulling/pull-by-lot', [OperatorApiController::class, 'pullByLotNumber']);

        // ===== SLOT INFORMATION =====
        // Get slot information
        Route::get('/operator/slot/{slotName}', [OperatorApiController::class, 'getSlotInfo']);
        
        // NEW: Get lot numbers for specific slot (matches web controller)
        Route::get('/operator/slot/{slotName}/lots', [OperatorApiController::class, 'getSlotLotNumbers']);

        // ===== SEARCH AND UTILITIES =====
        Route::get('/operator/search/items', [OperatorApiController::class, 'searchItems']);
        Route::get('/operator/activities', [OperatorApiController::class, 'getActivityHistory']);

        // ===== LEGACY ROUTES (deprecated but kept for backward compatibility) =====
        // These can be removed if not used by existing clients
        Route::post('/operator/store/scan-slot', [OperatorApiController::class, 'scanSlotForStore'])->name('api.deprecated.scan-slot-store');
        Route::post('/operator/store/by-erp', [OperatorApiController::class, 'storeByErp'])->name('api.deprecated.store-by-erp');
        Route::post('/operator/pull/scan-slot', [OperatorApiController::class, 'scanSlotForPull'])->name('api.deprecated.scan-slot-pull');
        Route::post('/operator/pull/by-lot', [OperatorApiController::class, 'pullByLotNumber'])->name('api.deprecated.pull-by-lot');
    });
});