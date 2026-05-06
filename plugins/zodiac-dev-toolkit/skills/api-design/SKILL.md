---
name: api-design
description: >
  REST API design patterns for My Zodiac AI — endpoint naming, DTOs, validation,
  versioning, error responses, and pagination. Use when the user asks to "create API",
  "add endpoint", "design REST API", "create DTO", "add validation", "API дизайн",
  "создай эндпоинт", "добавь валидацию", or needs guidance on controller, DTO, or
  response structure patterns.
---

# API Design — My Zodiac AI

## Versioned API Structure

```
/api/v1/...   # Stable, production
/api/v2/...   # Next version
/api/v3/...   # Latest (e.g., cosmic-weather-v3)
```

## Controller Pattern

```typescript
// controllers/v3/cosmic-weather-v3.controller.ts
@Controller('v3/cosmic-weather')
@UseGuards(JwtAuthGuard)
@ApiTags('Cosmic Weather v3')
export class CosmicWeatherV3Controller {
  constructor(private readonly cosmicWeatherService: CosmicWeatherService) {}

  @Get('daily/:userId')
  @ApiOperation({ summary: 'Get daily cosmic weather' })
  @ApiResponse({ status: 200, type: CosmicWeatherResponseDto })
  async getDaily(
    @Param('userId', ParseObjectIdPipe) userId: string,
    @CurrentUser() currentUser: UserPayload,
  ): Promise<CosmicWeatherResponseDto> {
    return this.cosmicWeatherService.getDaily(userId);
  }

  @Get('forge-alerts/:userId')
  @ApiOperation({ summary: 'Get active forge alerts' })
  async getForgeAlerts(
    @Param('userId', ParseObjectIdPipe) userId: string,
    @Query() query: ForgeAlertsQueryDto,
  ): Promise<PaginatedResponse<ForgeAlertDto>> {
    return this.cosmicWeatherService.getForgeAlerts(userId, query);
  }
}
```

## DTO Pattern

```typescript
// dto/cosmic-weather-response.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNumber, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class ForgeAlertDto {
  @ApiProperty() @IsString() id: string;
  @ApiProperty() @IsString() title: string;
  @ApiProperty({ enum: ['low', 'medium', 'high', 'critical'] })
  severity: string;
  @ApiProperty() @IsString() description: string;
  @ApiProperty() isActive: boolean;
}

export class CosmicWeatherResponseDto {
  @ApiProperty() @IsString() userId: string;
  @ApiProperty() date: Date;
  @ApiProperty({ type: [ForgeAlertDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ForgeAlertDto)
  forgeAlerts: ForgeAlertDto[];
  @ApiProperty() @IsNumber() overallScore: number;
}
```

## Query DTO with Pagination

```typescript
export class ForgeAlertsQueryDto {
  @IsOptional() @IsNumber() @Min(1) page?: number = 1;
  @IsOptional() @IsNumber() @Min(1) @Max(100) limit?: number = 20;
  @IsOptional() @IsEnum(SeverityLevel) severity?: SeverityLevel;
  @IsOptional() @IsBoolean() @Transform(({ value }) => value === 'true') activeOnly?: boolean;
}
```

## Paginated Response

```typescript
export class PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}
```

## Error Responses

```typescript
// Standard error format
{
  "statusCode": 404,
  "errorCode": "NATAL_CHART_NOT_FOUND",
  "message": "Natal chart not found for user",
  "timestamp": "2026-03-15T12:00:00.000Z"
}
```

Use project error codes from `@common/enums/error-code.enum`.

## Auth Guards

- `@UseGuards(JwtAuthGuard)` — requires valid JWT
- `@UseGuards(TierGuard)` — checks subscription tier
- `@CurrentUser()` decorator — extracts user from JWT payload

## Naming Conventions

| Method | Path | Action |
|--------|------|--------|
| GET | `/v3/cosmic-weather/daily/:userId` | Read one |
| GET | `/v3/cosmic-weather/forge-alerts/:userId` | List with filters |
| POST | `/v3/cosmic-weather/calculate` | Create/trigger |
| PATCH | `/v3/cosmic-weather/:id` | Partial update |
| DELETE | `/v3/cosmic-weather/:id` | Delete |

## Rules

1. **Always version APIs** — `/v1/`, `/v2/`, `/v3/`
2. **Use DTOs for all inputs/outputs** — never expose raw schemas
3. **Validate with class-validator** — `@IsString()`, `@IsNumber()`, etc.
4. **Document with Swagger** — `@ApiProperty()`, `@ApiOperation()`
5. **Use `ParseObjectIdPipe`** for MongoDB ObjectId params
6. **Paginate list endpoints** — page/limit with PaginatedResponse
7. **Use error codes** — machine-readable `errorCode` field
