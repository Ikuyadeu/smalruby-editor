window.SmalrubyEditor = {}
window.changed = false
window.textEditor = null
window.blockMode = true

window.successMessage = (title, msg = '', selector = '#messages') ->
  html = $('<div class="alert alert-success" style="display: none">')
    .append("<h4><i class=\"icon-star\"></i>#{title}</h4>")
    .append(msg)
  $(selector).append(html)
  html.fadeIn('slow')
    .delay(3000)
    .fadeOut('slow')

window.errorMessage = (msg, selector = '#messages') ->
  html = $('<div class="alert alert-error" style="display: none">')
    .append('<button type="button" class="close" data-dismiss="alert">×</button>')
    .append('<h4><i class="icon-exclamation-sign"></i>エラー</h4>')
    .append(msg)
  $(selector).append(html)
  html.fadeIn('slow')

window.Smalruby =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  initialize: ->
    # HACK: Underscoreのテンプレートの<%, %>はHamlと組み合わせたときに
    #   HTML要素の属性がHamlによってエスケープされてしまうため使いにく
    #   い。そこで、それぞれ{{, }}に変更する。
    _.extend(_.templateSettings, {
      escape: /{{-([\s\S]+?)}}/
      evaluate: /{{([\s\S]+?)}}/
      interpolate: /{{=([\s\S]+?)}}/
    })

    @Collections.CharacterSet = new Smalruby.CharacterSet()

    @Views.MainMenuView = new Smalruby.MainMenuView()
    @Views.CharacterSelectorView = new Smalruby.CharacterSelectorView
      model: @Collections.CharacterSet
    @Views.CharacterModalView = new Smalruby.CharacterModalView
      el: $('#character-modal')

    $('a[data-toggle="tab"]').on 'shown', (e) ->
      if $(e.target).attr('href') == '#block-tab'
        window.blockMode = true
      else
        window.blockMode = false
        data = Blockly.Ruby.workspaceToCode()
        if $.trim(data).length > 0
          window.textEditor.getSession().getDocument().setValue(data)
          window.textEditor.moveCursorTo(0, 0)
        window.textEditor.focus()

    Smalruby.downloading = false
    window.onbeforeunload = (event) ->
      if !Smalruby.downloading && window.changed
        return '作成中のプログラムが消えてしまうよ！'
      else
        Smalruby.downloading = false
        return

    Blockly.HSV_SATURATION = 1.0
    Blockly.HSV_VALUE = 0.8

    Blockly.inject document.getElementById('blockly-div'),
      path: '/blockly/'
      toolbox: document.getElementById('toolbox')
      trashcan: true

    Blockly.Toolbox.tree_.expandAll()

    @blocklyFirst = true
    @blocklyLoading = false
    Blockly.addChangeListener =>
      # HACK: Blocklyを初期化後に一回だけChangeListenerが呼び出させれ
      # る。ここではそれを無視している。
      if @blocklyFirst
        @blocklyFirst = false
        return

      # HACK: XMLの読み込み後に一回だけChangeListenerが呼び出させれ
      # る。ここではそれを無視している。
      if @blocklyLoading
        @blocklyLoading = false
        return

      window.changed = true

  loadXml: (data, workspace = Blockly.mainWorkspace) ->
    xml = Blockly.Xml.textToDom(data)
    workspace.clear()
    chars = []
    i = 0
    while (xmlChild = xml.childNodes[i])
      if xmlChild.nodeName.toLowerCase() == 'character'
        c = new Smalruby.Character
          name: xmlChild.getAttribute('name')
          costumes: xmlChild.getAttribute('costumes').split(',')
          x: parseInt(xmlChild.getAttribute('x'), 10)
          y: parseInt(xmlChild.getAttribute('y'), 10)
          angle: parseInt(xmlChild.getAttribute('angle'), 10)
        chars.push(c)
      i++
    Smalruby.Collections.CharacterSet.reset(chars)
    Blockly.Xml.domToWorkspace(workspace, xml)

  dumpXml: (workspace = Blockly.mainWorkspace, charSet = Smalruby.Collections.CharacterSet) ->
    xmlDom = Blockly.Xml.workspaceToDom(workspace)
    blocklyDom = xmlDom.firstChild
    charSet.each (c) ->
      e = goog.dom.createDom('character')
      e.setAttribute('x', c.get('x'))
      e.setAttribute('y', c.get('y'))
      e.setAttribute('name', c.get('name'))
      e.setAttribute('costumes', c.get('costumes').join(','))
      e.setAttribute('angle', c.get('angle'))
      xmlDom.insertBefore(e, blocklyDom)
    Blockly.Xml.domToPrettyText(xmlDom)

$(document).ready ->
  Smalruby.initialize()
