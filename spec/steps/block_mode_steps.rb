# encoding: utf-8

step '次のブロックを配置する:' do |haml|
  haml = %(%xml{:xmlns => "http://www.w3.org/1999/xhtml"}\n) +
    haml.lines.map { |s| "  #{s}" }.join
  engine = Haml::Engine.new(haml)
  xml = engine.render
  page.execute_script(<<-JS)
    do {
      var dom = Blockly.Xml.textToDom('#{escape_javascript(xml)}');
      Blockly.Xml.domToWorkspace(Blockly.mainWorkspace, dom);
    } while (false);
  JS
end

step 'すべてのブロックをクリアする' do
  page.execute_script('Blockly.mainWorkspace.clear()')
end

step 'ブロックからソースコードを生成する' do
  step '"Rubyタブ" にタブを切り替える'
end

step '次のキャラクターを追加する:' do |table|
  table.hashes.each do |h|
    costumes = h['costumes'].split(',').map { |s| "'#{s}'" }.join(', ')
    page.execute_script(<<-JS)
      Smalruby.Collections.CharacterSet.add(new Smalruby.Character({
        name: '#{h['name']}',
        costumes: [#{costumes}],
        x: #{h['x']},
        y: #{h['y']},
        angle: #{h['angle']}
      }))
    JS
  end
end
