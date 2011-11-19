class App.backbone.List extends Backbone.Model
  change: -> @save()

  updateItems: ->
    @set
      items: App.mainList.view.serialize()

  isEmpty: ->
    @get('items').length == 1 && @get('items')[0].body == ""


class App.backbone.Lists extends Backbone.Collection
  model: App.backbone.List
  url:   "/lists"

class App.backbone.ItemFormView extends Backbone.View
  tagName: "form"
  template: _.template "<input type='text' value='' />"
  events:
    submit: "submit"
    keydown: "handleKey"
    "keydown input": "handleInputKey"
    "blur input": "stopEditing"

  initialize: (itemData) ->
    @itemData = itemData

  submit: ->
    @stopEditing()
    App.mainList.view.newItem()
    false

  stopEditing: ->
    val = @$("input").val()
    @itemData.body = val
    $(@el).parents("li")[0].view.switchToShow()

  handleKey: (event) ->
    keyCode = event.keyCode.toString()
    if keyCode == "27"
      @stopEditing()
    else if keyCode == "13"
      @stopEditing()
      App.mainList.view.newItem()

  handleInputKey: (event) ->
    keyCode = event.keyCode.toString()
    if keyCode == "27"
      @stopEditing()
      false
    else if keyCode == "38"
      prev = App.selection().previous()
      if prev
        @stopEditing()
        prev.select()
        prev.switchToForm()
      false
    else if keyCode == "40"
      next = App.selection().next()
      if next
        @stopEditing()
        next.select()
        next.switchToForm()
      false

  render: ->
    $(@el).html @template()
    @$("input:first").val @itemData.body
    this

class App.backbone.ItemView extends Backbone.View
  tagName: "li"
  template: _.template("<div class='item'><div class='body'></div></div>")
  initialize: (itemData) ->
    @itemData = itemData

  events:
    "change input[type=\"checkbox\"]": "changeStatus"
    "click .item.selected": "preventFurtherClicks"
    "click .item": "click"
    "dblclick .item.selected input": "preventFurtherClicks"
    "dblclick .item": "switchToForm"
    "drag": "handleDrag"

  handleDrag: ->
    App.mainList.updateItems()
    @select()
    e.stopImmediatePropagation()
        
  changeStatus: ->
    App.mainList.updateItems()

  click: ->
    @select()

  preventFurtherClicks: (e) ->
    e.stopImmediatePropagation()

  dblclick: ->
    @switchToForm()

  setClasses: ->
    @item.attr "class", "item"
    @item.addClass @itemData.status
    @item.addClass @itemData.item_type
    # TODO handle selected

  select: ->
    if App.selection()
      App.selection().deselect()
    @item.addClass "selected"

  deselect: ->
    @form.stopEditing() if @$("form").length
    @item.removeClass "selected"

  setBody: ->
    @body.html @itemData.body + "&nbsp;"

  moveUp: ->
    $(@el).insertBefore $(@el).prev()
    App.mainList.updateItems()

  moveDown: ->
    $(@el).insertAfter $(@el).next()
    App.mainList.updateItems()

  next: ->
    all = $("#app li").toArray()
    index = all.indexOf(@el)
    if index < all.length - 1
      index++
    all[index].view

  previous: ->
    all = $("#app li").toArray()
    index = all.indexOf(@el)
    if index > 0
      index--
    all[index].view

  indent: ->
    if $(@el).prev("li").length
      $($(@el).prev("li")[0].view.childrenView.el).append @el
      App.mainList.updateItems()

  outdent: ->
    if $(@el).parents("li").length
      $(@el).insertAfter $(@el).parents("li")[0]
      App.mainList.updateItems()

  render: ->
    that = this
    $(@el).html @template(@itemData)
    @item = $(@el).children(".item")
    @body = @item.children(".body")
    @setBody()
    @status = $("<input type='checkbox' />")
    if @itemData.status == "checked"
      @status.attr "checked", true
    else
      @status.attr "checked", false
    $(@item).prepend @status
    @childrenView = new App.backbone.ItemChildrenView(@itemData.children)
    $(@el).append @childrenView.render().el
    @setClasses()
    @el.view = @
    this

  switchToForm: ->
    @form = new App.backbone.ItemFormView(@itemData)
    @body.replaceWith @form.render().el
    $(@form.el).find("input").focus()

  switchToShow: ->
    @setBody()
    $(@form.el).replaceWith @body
    App.mainList.updateItems()

class App.backbone.ItemChildrenView extends Backbone.View
  tagName: "ol"
  className: "children"
  initialize: (childrenData) ->
    @childrenData = childrenData
  render: ->
    that = this
    if @childrenData
      for child in @childrenData
        lv = new App.backbone.ItemView(child)
        $(that.el).append lv.render().el

    this

class App.backbone.ListPropertiesView extends Backbone.View
  render: ->
    @$(".name").text(@model.get("name"))
    $(".list-#{@model.get("id")} a").text(@model.get("name"))
    @$(".description").text(@model.get("description"))
    this

class App.backbone.ListPropertiesFormView extends Backbone.View
  events:
    "click  .primary"     : "close"
    "submit form"         : "close"
    "blur   .name"        : "update"
    "blur   .description" : "update"

  render: ->
    @$(".name").val(@model.get("name"))
    @$(".description").val(@model.get("description"))
    this

  update: ->
    @model.set
      name: @$(".name").val()
      description: @$(".description").val()

  close: ->
    @update()
    $("#properties-form").modal("hide")
    false

  cancel: ->
    @render()
    $("#properties-form").modal("hide")

class App.backbone.ListView extends Backbone.View
  tagName: "ol"
  className: "item-list"

  initialize: ->
    _.bindAll @, "selectPrevious", "selectNext", "switchItem", "toggleStatus", "moveSelectionUp", "moveSelectionDown", "indentItem", "outdentItem", "newItem", "deleteItem"

  serialize: ->
    items = []
    
    serializer = (el)->
      item = {}
      item.body = $(el).children(".item").text()
      item.status = $(el).find(">.item input[type=checkbox]")[0].checked ? "checked" : ""
      item.children = []
      item.children.push(serializer(child)) for child in $(el).find(">ol>li").toArray()
      item
      
    @$(">li").each (i, el) ->
      items.push serializer(el)
    
    items

  firstChild: ->
    @el.firstChild.view

  selectPrevious: ->
    if not App.selected and App.selection()
      App.selection().select()
    else
      App.selection()?.previous()?.select()
    false

  selectNext: ->
    if not App.selected and App.selection()
      App.selection().select()
    else
      App.selection()?.next()?.select()
    false

  switchItem: ->
    App.selection().switchToForm()

  toggleStatus: ->
    App.selection().toggleStatus()
    false

  moveSelectionUp: (event) ->
    App.selection().moveUp()
    false

  moveSelectionDown: (event) ->
    App.selection().moveDown()
    false

  indentItem: ->
    App.selection().indent()

  outdentItem: ->
    App.selection().outdent()

  newItem: (placement) ->
    selection = App.selection()
    itemView = new App.backbone.ItemView
      body: ""
      status: ""
      children: []

    itemView.render()
    if selection
      if placement == "previous"
        $(itemView.el).insertBefore selection.el
      else
        if $(selection.el).children("li").size() > 0
          selection = $(selection.el).children("li")[0]
          $(itemView.el).insertBefore selection
        else
          if placement == "indent"
            $(itemView.el).insertAfter selection.el
            itemView.indent()
          else # insert after
            $(itemView.el).insertAfter selection.el
    else
      $(@el).append itemView.el
    itemView.select()
    _.defer ->
      App.selection().switchToForm()

  deleteItem: ->
    App.selection().remove()
    false

  render: ->
    that = this
    for item in @collection
      lv = new App.backbone.ItemView(item)
      $(that.el).append lv.render().el

    this


new App.Slice
  name: 'list'
  keyBindings:
    "up"           : ->
      App.mainList.view.selectPrevious()
    "down"         : ->
      App.mainList.view.selectNext()
    "esc"          : ->
      App.mainList.view.switchItem()
    "ctrl+up"      : ->
      App.mainList.view.moveSelectionUp()
    "ctrl+down"    : ->
      App.mainList.view.moveSelectionDown()
    "space"        : ->
      App.mainList.view.toggleStatus()
    "return"       : ->
      App.mainList.view.newItem()
    "ctrl+return"  : ->
      App.mainList.view.newItem "indent"
    "shift+return" : ->
      App.mainList.view.newItem "previous"
    "backspace"    : ->
      App.mainList.view.deleteItem()
    "del"          : ->
      App.mainList.view.deleteItem()
    "x"            : ->
      App.mainList.view.indentItem()
    "z"            : ->
      App.mainList.view.outdentItem()

  setupItems: (items) ->


  setup: ->
    list = App.data.list
    lists = new App.backbone.Lists([list])
    App.mainList = lists.at(0)
    @setupItems list.items
    App.mainList.view = new App.backbone.ListView(collection: App.mainList.get("items"))
    App.mainList.propertiesView = new App.backbone.ListPropertiesView(model: App.mainList, el: $("#properties"))
    App.mainList.propertiesFormView = new App.backbone.ListPropertiesFormView(model: App.mainList, el: $("#properties-form"))

    $(App.appId).append App.mainList.view.render().el
    App.mainList.view.selectNext()
    App.mainList.view.switchItem() if App.mainList.isEmpty()
    App.sliceManager.activateSlice('list')
    $("#app ol.item-list").nestedSortable
      placeholder: "drag-drop-placeholder"
      forcePlaceholderSize: true
      handle: 'div.body'
      helper: 'clone'
      items: 'li'
      tolerance: 'pointer'
      toleranceElement: '> div'
      stop: (event, ui) ->
        $(ui.item['0']).trigger('drag')

  activate: ->
    App.Pages.activatePage('list')