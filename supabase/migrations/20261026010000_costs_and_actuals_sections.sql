-- New sections: cost lines with categories ('costs', replaces 'opex'), category names ('cats') and Jan to Sep actuals ('actuals').
alter table public.model_sections drop constraint if exists model_sections_section_check;
alter table public.model_sections add constraint model_sections_section_check check (section in (
  'general', 'streams', 'opex', 'costs', 'employees', 'prepay', 'debtors', 'creditors', 'cats', 'actuals',
  'p0', 'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9'
));
