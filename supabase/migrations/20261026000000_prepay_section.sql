-- Allow the prepayments section to be saved.
alter table public.model_sections drop constraint if exists model_sections_section_check;
alter table public.model_sections add constraint model_sections_section_check check (section in (
  'general', 'streams', 'opex', 'employees', 'prepay', 'debtors', 'creditors',
  'p0', 'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9'
));
