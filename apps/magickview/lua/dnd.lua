
local num_files = gh_utils.drop_files_get_num_files()
if (num_files > 0) then
  local full_path = gh_utils.drop_files_get_file_by_index(0)
  --print("DND - " .. full_path)
  filename_src = full_path
  load_image_dnd = 1
  load_image = 1
end

