# Frontend E2E Test Matrix

## 1. 用例映射
| E2E-ID | REQ Ref | Page Path | Scenario | Expected |
| --- | --- | --- | --- | --- |
| FE-E2E-001 | REQ-002-1;REQ-003-1;REQ-004-2;REQ-004-3 | / (Main) | Switch view to Calendar and List, click date | View content renders and date list visible |
| FE-E2E-002 | REQ-002-4 | / (Main) | Drag task card to Doing column | Status updates and card visible in Doing |
| FE-E2E-003 | REQ-007-1;REQ-007-3;REQ-007-4 | /review | Open Review, switch range, edit note and reload | Stats visible and note persisted |
| FE-E2E-004 | REQ-008-3;REQ-006-1 | /settings | Open Settings and see Markdown import | Import control visible |
| FE-E2E-005 | REQ-005-2 | / (Main) | Create due reminder task | Reminder banner visible |
| FE-E2E-006 | NFR-001-1 | / (Main) | Initial load performance | Navigation duration < 2s |
| FE-E2E-007 | REQ-009-2 | / (Main) | Add task then reload | Task persists after reload |

## 2. 执行记录
| E2E-ID | 执行时间 | 结果 | 证据 |
| --- | --- | --- | --- |
| FE-E2E-001 | 2026-02-27 | PASS | playwright test: main view renders and switches views |
| FE-E2E-002 | 2026-02-27 | PASS | playwright test: drag task card between columns |
| FE-E2E-003 | 2026-02-27 | PASS | playwright test: review page shows stats and notes |
| FE-E2E-004 | 2026-02-27 | PASS | playwright test: settings page shows markdown import |
| FE-E2E-005 | 2026-02-27 | PASS | playwright test: reminder banner appears for due tasks |
| FE-E2E-006 | 2026-02-27 | PASS | playwright test: initial load under 2s |
| FE-E2E-007 | 2026-02-27 | PASS | playwright test: local data persists across reload |

## 3. 执行记录模板
| E2E-ID | 执行时间 | 结果 | 证据 |
| --- | --- | --- | --- |
| FE-E2E-XXX | YYYY-MM-DD | PASS/FAIL | 命令输出/截图/日志 |

## 4. Note
UI quality gate has been moved to `final-delivery` (`FD-UI-001`).
