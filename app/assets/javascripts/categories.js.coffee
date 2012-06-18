# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  makeTag $('#categories .tags')
  makeEditable $('#categories .editable')
  $('#categories').on 'click', '.add-sub', add_new_subcategory
  $('#add-category button').click add_new_category
  $('#categories .form-actions input[name="save"]').click ->
    $(@).addClass('disabled').attr('value', 'Saving...')
  
tagHtml = '<input class="tags" />'
  
makeTag = ($selector) ->
  $selector.tagsInput
    "defaultText": "add here"
    "removeWithBackspace": true
    "width": 400
    "onAddTag": (tag) ->
      console.log "#{tag} added"
      $targetField = find_matches_field.call(@)

      if $targetField.length == 0
        editSubcategory.apply @, {
          current: $(@).parents('.tr').find('.int-name').html()
          previous: ""
        }

      values = $targetField.attr('value')
      if values.length > 0
        values = values.split(',')
      else
        values = []
      values.push(tag)
      console.log values
      $targetField.attr('value', values.join(","))
      console.log $targetField

    "onRemoveTag": (tag) ->
      console.log "#{tag} removed"
      $targetField = find_matches_field.call(@)

      if $targetField.length == 0
        return
      
      # get values
      values = $targetField.attr('value').split(',')
      return if values.length == 0
      
      # Adjust value by removing tag
      tagIndex = values.indexOf(tag)
      if tagIndex >= 0
        values.splice(tagIndex, 1)
        
      # Set value to target hidden field
      $targetField.attr('value', values.join(","))
      console.log $targetField
      
# Find the matches field for this match input
find_matches_field = ->
  if $(@).parents('.main-cat').length > 0
    $targetField = find_target_field.call(@, 'matches')
  else
    subName = $(@).parent('td').find('.tags').first().attr('data-target')
    $targetField = find_target_field.call(@, subName)

# Find the hidden field based on the supply field
find_target_field = (field) ->
  $(@).parents('.category').find("input[name=\"#{field}\"]").first()

makeEditable = ($selector) ->
  $selector.editable
    onSubmit: editCallback

editCallback = (content) ->
  if $(@).parents('.sub-cat').length > 0
    editSubcategory.call @, content
  else if $(@).hasClass('cat-name')
    editCategory.call @, content

editCategory = (content) ->
  if content.current.length == 0
    content.current = "New Category"
    $(@).html content.current
  @.parents('.category').find('.hidden-attributes input[name="name"]')
    .attr('value', content.current)
  
editSubcategory = (content) ->
  # Do nothing if value didn't change
  if content.current == content.previous
    return
  
  newName = "#{to_camel(content.current)}_matches"
  oldName = "#{to_camel(content.previous)}_matches"
  $parentCateogry = $(@).parents('.category')
  
  # Handle when no value is supplied
  if content.current.length == 0
    remove_sub_category.call $(@), content.previous, oldName
    return
  
  # Handle when its the default value
  isDefault = false
  if content.current == "New Subcategory"
    isDefault = true
  
  # Update tag info
  $(@).parents('tr').find('.tags:first').attr('data-target', newName)
  
  # Remove any old field
  preValues = ""
  $oldSelector = $parentCateogry.find("input[name=\"#{oldName}\"]")
  if $oldSelector.length > 0 
    preValues = $oldSelector.attr('value')
    $oldSelector.remove()
  
  # Create new subcat values
  $newHidden = $("<input name=\"#{newName}\" type=\"hidden\" value=\"#{preValues}\" />")
  $newHidden.appendTo $parentCateogry.find('.hidden-attributes:first')
  
  # Remove previous subcategory name
  $subnames = $parentCateogry.find('input[name="sub_names"]')
  if $subnames.attr('value').length == 0
    preSubs = []
  else preSubs = $subnames.attr('value').split(',')
  prevSubsIndex = preSubs.indexOf content.previous
  if prevSubsIndex >= 0
    preSubs.splice prevSubsIndex, 1
  
  # Add this subcategory unless its default
  preSubs.push content.current unless isDefault
  $subnames.attr('value', preSubs.join(','))

resetCategoryData = ($selector) ->
  makeEditable $selector.find('.cat-name').html('New Category')
  $newTag = $selector.find('.main-cat th:nth-child(2)')
    .html(tagHtml).find('.tags:first')
  $selector.find('.sub-cat tbody').html(null)
  $selector.find('.hidden-attributes')
    .html('<input name="name" type="hidden" value="New Cateogry" />')
  $hidden = $selector.find('.hidden-attributes:first')
  $hidden.append '<input name="sub_names" type="hidden" />'
  $hidden.append '<input name="matches" type="hidden" />'
  $selector
  
add_new_category = ->
  $newCat = $('#categories .category:first').clone()
  $newCat = resetCategoryData $newCat
  $('#categories').prepend $newCat
  makeTag $newCat.find('.main-cat .tags:first')
  
add_new_subcategory = ->
  console.log 'adding new category'
  $subCat = $(@).parents('.category').find('.sub-cat tbody')
  $newRow = $('#categories .sub-cat tbody tr').first().clone()
  $newRow.find('.editable').html('New Subcategory')
  $newRow.find('td:nth-child(2)').html tagHtml
  $newRow.appendTo $subCat
  
  # Create this subcat hidden field
  editSubcategory.call $newRow.find('.editable'),
    current: "New Subcategory"
    previous: ""
  
  makeTag $newRow.find('.tags').first()
  makeEditable $newRow.find('.editable')
  
to_camel = (words) ->
  result = ""
  for word in words.split(' ')
    if result.length > 0
      result += word.toUpperCase().charAt(0) + word.substring(1)
    else
      result += word.toLowerCase()
  result
  
remove_sub_category = (catName, targetTag) ->
  console.log @
  console.log catName
  $subNamesSelector = @.parents('.category').find('input[name="sub_names"]')
  console.log $subNamesSelector
  subValues = $subNamesSelector.attr('value')
  console.log subValues
  if subValues.length == 0
    subValues = []
  else
    subValues = subValues.split(',')
  catIndex = subValues.indexOf catName
  if catIndex >= 0
    subValues.splice catIndex, 1
  $subNamesSelector.attr('value', subValues.join(','))
  @.parents('.category').find("input[name=\"#{targetTag}\"]").remove()
  @.parents('tr:first').remove()