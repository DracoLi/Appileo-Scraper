# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  makeTag $('#interests .tags')
  makeEditable $('#interests .editable')
  $('#interests').on 'click', '.add-int', add_new_interest
  $('#interests').on 'click', '.int-gender button', edit_gender
  $('#interests .form-actions input[name="save"]').click ->
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

      # If no submit values for this interest, then add it
      if $targetField.length == 0
        editCallback.apply @, {
          current: $(@).parents('.tr').find('.sub-name').html()
          previous: ""
        }
      
      # Update submit values for this interest
      values = $targetField.attr('value')
      values = if values.length > 0 then values.split(',') else []
      values.push tag
      console.log "subcategory values: #{values}"
      $targetField.attr 'value', values.join(",")
      console.log "Target field:"
      console.log  $targetField
    
    "onRemoveTag": (tag) ->
      console.log "#{tag} removed"
      $targetField = find_matches_field.call(@)
      
      # Do nothing if interst is not registered
      if $targetField.length == 0
        return

      # get values, return if nothing to remove
      values = $targetField.attr('value').split(',')
      return if values.length == 0

      # Adjust value by removing tag
      tagIndex = values.indexOf(tag)
      if tagIndex >= 0 then values.splice(tagIndex, 1)

      # Set value to target hidden field
      $targetField.attr 'value', values.join(",")
      console.log "Target field: #{$targetField}"

# Find the matches field for this interest tag
find_matches_field = ->
  target_match = $(@).parents("tr").find(".tags").attr 'data-target'
  $(@).parents('#interests').find("input[name=\"#{target_match}\"]").first()

makeEditable = ($selector) ->
  $selector.editable
    onSubmit: editCallback

editCallback = (content) ->
  # Do nothing if value didn't change
  if content.current == content.previous
    return
  
  newName = "#{to_camel(content.current)}_matches"
  oldName = "#{to_camel(content.previous)}_matches"
  $interests = $(@).parents('#interests')
  
  # Handle when no value is supplied
  if content.current.length == 0
    remove_interest.call @, content.previous, oldName
    return
  
  # Handle when its the default value
  isDefault = false
  if content.current == "New Interest"
    isDefault = true
  
  # Update tag info
  $(@).parents('tr').find('.tags').attr 'data-target', newName

  # Remove any old field
  preValues = ""
  $oldSelector = $interests.find("input[name=\"#{oldName}\"]")
  if $oldSelector.length > 0 
    preValues = $oldSelector.attr('value')
    $oldSelector.remove()
  
  # Create new interest matches values
  $newHidden = $("<input name=\"#{newName}\" type=\"hidden\" value=\"#{preValues}\" />")
  $newHidden.appendTo $interests.find('.hidden-attributes:first')

  # Remove previous interest name
  $intNames = $interests.find('input[name="int_names"]')
  preSubs = 
    if $intNames.attr('value').length == 0
    then [] else $intNames.attr('value').split(',')
  prevSubsIndex = preSubs.indexOf content.previous
  if prevSubsIndex >= 0 then preSubs.splice(prevSubsIndex, 1)
  
  # Add this interest unless its default
  preSubs.push content.current unless isDefault
  $intNames.attr 'value', preSubs.join(',')
  
  # Create new interest gender values
  oldGenderName = "#{to_camel(content.previous)}_gender"
  newGenderName = "#{to_camel(content.current)}_gender"
  $interests.find("input[name=\"#{oldGenderName}\"]")
    .attr("name", newGenderName)
      
add_new_interest = ->
  console.log 'adding new interest'
  $newRow = $('#interests tbody tr').first().clone()
  $newRow.find('.editable').html('New Interest')
  $newRow.find('td:nth-child(3)').html tagHtml
  $newRow.appendTo $(@).parents('#interests').find('table tbody')

  # Create this interest hidden field
  editCallback.call $newRow.find('.editable'),
    current: "New Interest"
    previous: ""

  makeTag $newRow.find('.tags').first()
  makeEditable $newRow.find('.editable')

to_camel = (words) ->
  result = ""
  for word in words.split(' ')
    result +=
      if result.length > 0 
      then word.toUpperCase().charAt(0) + word.substring(1)
      else word.toLowerCase()
  result

remove_interest = (intName, targetTag) ->
  $intSelector =
    $(@).parents('#interests').find('input[name="int_names"]')
  console.log "Interest Selector:" 
  console.log $intSelector
  
  # Update interest field's value
  intValues = $intSelector.attr('value')
  intValues = if intValues.length == 0 then [] else intValues.split(',')
  intIndex = intValues.indexOf intName
  if intIndex >= 0 then intValues.splice(intIndex, 1)
  $intSelector.attr 'value', intValues.join(',')
  
  # Remove interest row
  $(@).parents('#interests').find("input[name=\"#{targetTag}\"]").remove()
  $(@).parents('tr').remove()
  
edit_gender = ->
  newValue = $(@).html()
  interestName = $(@).parents('tr').find('.int-name').html()
  console.log "interest name: #{interestName}"
  selectorName = "#{to_camel(interestName)}_gender"
  $interests = $(@).parents('#interests')
  
  # Create new hidden gender field if none
  if $interests.find("input[name=\"#{selectorName}\"]").length == 0
    $hidden = $interests.find('.hidden-attributes')
    $hidden.append "<input name=\"#{selectorName}\" type=\"hidden\" />"
    
  # Edit the gender value
  $target = $interests.find("input[name=\"#{selectorName}\"]")
  $target.attr('value', newValue)