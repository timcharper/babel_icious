Given /^a mapping exists for '(.*)' to '(.*)' with tag '(.*)'$/ do |source, target, mapping_tag|
  @direction = {:from => source.to_sym, :to => target.to_sym}
  @tag = mapping_tag
  
  case @direction
  when {:from => :xml, :to => :hash}
    Babelicious::Mapper.config(@tag.to_sym) do |m|
      m.direction :from => :xml, :to => :hash

      m.map :from => "foo/bar", :to => "bar/foo"
      m.map :from => "foo/baz", :to => "bar/boo"
      m.map :from => "foo/cuk/coo", :to => "foo/bar/coo"
      m.map :from => "foo/cuk/doo", :to => "doo"
    end
  when {:from => :hash, :to => :xml}
    Babelicious::Mapper.config(@tag.to_sym) do |m|
      m.direction :from => :hash, :to => :xml

      m.map :from => "foo/bar", :to => "bar/foo"
      m.map :from => "foo/baz", :to => "bar/boo"
      m.map :from => "foo/cuk/coo", :to => "bar/cuk/coo"
      m.map :from => "foo/cuk/doo", :to => "bar/cuk/doo"
    end
  when {:from => :hash, :to => :hash}
    Babelicious::Mapper.config(@tag.to_sym) do |m|
      m.direction :from => :hash, :to => :hash

      m.map :from => "foo", :to => "zoo"
      m.map :from => "bar", :to => "yoo"
      m.map :from => "baz", :to => "too"
      m.map :from => "boo", :to => "soo/roo"
    end
  end
end

Given /^a mapping exists with '(.*)' condition$/ do |condition|
  case condition
  when /unless/
    Babelicious::Mapper.config(:ignore) do |m|
      m.direction :from => :xml, :to => :hash

      m.map :from => "foo/bar", :to => "bar/foo"
      m.map(:from => "foo/baz", :to => "bar/boo").unless(:empty)
    end
 when /when/
    Babelicious::Mapper.config(:when) do |m|
      m.direction :from => :xml, :to => :hash

      m.map(:from => "foo/bar", :to => "bar/foo").when do |value|
        value =~ /hubba/
      end 
      m.map(:from => "foo/baz", :to => "bar/boo").when do |value|
        value =~ /bubba/
      end 
    end
  end
end

Given /^a mapping exists with concatenation$/ do
  Babelicious::Mapper.config(:concatenation) do |m|
    m.direction :from => :xml, :to => :hash

    # <event><decision_request><target_factors><institutions><institution>FOO</institution><institution>BAR</institution><institution>BAZ</institution></institutions></target_factors></decision_request></event>
    m.map(:from => "event/decision_request/target_factors/institutions", :to => "event/new_update_status_code").customize do |node|
      node.concatenate_children("|")
    end
  end
end

Given /^a mapping exists with a customized block$/ do
  Babelicious::Mapper.config(:customized) do |m|
    m.direction :from => :xml, :to => :hash
    
    # <event><progress><statuses><status><code>Abandoned</code><message>bad phone</message></status></statuses></progress></event>
    m.map(:from => "event/progress/statuses", :to => "event/new_update_status_code").customize do |node|
      res = []
      node.elements.map { |nd| res << {"name" => nd.child_content("code"), "text" => nd.child_content("message")} }
      res
    end
  end 
end

Given /^a mapping exists with custom \.to method$/ do
  Babelicious::Mapper.config(:custom_to) do |m|
    m.direction :from => :xml, :to => :hash

    # xml = "<foo><bar>baz</bar></foo>"
    m.from("foo/bar").to do |value|
      if(value == "baz")
        "value/was/baz"
      else 
        "value/was/not/baz"
      end 
    end
  end 
end

Given /^a mapping exists with include$/ do
  Babelicious::Mapper.config(:another_map) do |m|
    m.direction :from => :hash, :to => :hash

    m.map :from => "foo", :to => "zoo"
    m.map :from => "bar", :to => "yoo"
  end

  Babelicious::Mapper.config(:include_another_map) do |m|
    m.direction :from => :hash, :to => :hash

    m.include :another_map
    m.map :from => "baz", :to => "too"
    m.map :from => "boo", :to => "soo/roo"
  end
end

Given /^a contact mapping exists with nested include$/ do
  Babelicious::Mapper.config(:a_sample_person) do |m|
    m.direction :from => :hash, :to => :hash

    m.map :from => "name/first", :to => "first_name"
    m.map :from => "name/last", :to => "last_name"
  end

  Babelicious::Mapper.config(:a_sample_contact) do |m|
    m.direction :from => :hash, :to => :hash

    m.include :a_sample_person, :inside_of => "contact"
    m.map :from => "contact/phone/home", :to => "contact/home_phone"
  end
end



#
##
###
When /^the mapping is translated$/ do
  case @direction
  when {:from => :xml, :to => :hash}
    xml = <<-EOL
<foo>
 <bar>a</bar>
 <baz>b</baz>
 <cuk>
  <coo>c</coo>
  <doo>d</doo>
 </cuk>
</foo>
EOL
    @translation = Babelicious::Mapper.translate(@tag.to_sym, xml)
  when {:from => :hash, :to => :xml}
    source = {:foo => {:bar => "a", :baz => "b", :cuk => {:coo => "c", :doo => "d"}}}
    @translation = Babelicious::Mapper.translate(@tag.to_sym, source)
  when {:from => :hash, :to => :hash}
    source = {:foo => "a", :bar => "b", :baz => "c", :boo => "d"}
    @translation = Babelicious::Mapper.translate(@tag.to_sym, source)
  end
end

When /^the '(.*)' mapping is translated$/ do |condition|
  case condition
  when /unless/
    xml = '<foo><bar>a</bar><baz></baz></foo>'
    @translation = Babelicious::Mapper.translate(:ignore, xml)
  when /when/
    xml = '<foo><bar>cuk</bar><baz>hubbabubba</baz></foo>'
    @translation = Babelicious::Mapper.translate(:when, xml)
  end
end

When /^the mapping with concatenation is translated$/ do
#  xml = '<foo><bar>a</bar><baz>b</baz><cuk><coo>c</coo><coo>d</coo><coo>e</coo></cuk></foo>' 
  xml = <<-EOL
<event>
 <decision_request>
 <target_factors>
  <institutions>
   <institution>FOO</institution>
   <institution>BAR</institution>
   <institution>BAZ</institution>
  </institutions>
 </target_factors>
 </decision_request>
</event>
EOL
  @translation = Babelicious::Mapper.translate(:concatenation, xml)
end

When /^the customized mapping is translated$/ do
#  xml = '<foo><bar>baz</bar><cuk>coo</cuk></foo>'
#  xml = '<statuses><status><code>Abandoned</code><message>bad phone</message></status><status><code>Rejected</code><message>bad word</message></status></statuses>'
  xml = '<event><progress><statuses><status><code>Abandoned</code><message>bad phone</message></status><status><code>Rejected</code><message>bad word</message></status></statuses></progress></event>'
  @translation = Babelicious::Mapper.translate(:customized, xml)
end

When /^the mapping with custom \.to method is translated$/ do
  xml = "<foo><bar>baz</bar></foo>"
  @translation = Babelicious::Mapper.translate(:custom_to, xml)
end

When /^the mapping with include is translated$/ do
  hash = {:foo => "Dave", :bar => "Brady", :baz => "Liz", :boo => "Brady"}
  @translation = Babelicious::Mapper.translate(:include_another_map, hash)
end

When /^the mapping with nested include is translated$/ do
  hash = {:contact => {:name => {:first => "Dave", :last => "Brady"}, :phone => {:home => "1231231234"}}}
  @translation = Babelicious::Mapper.translate(:a_sample_contact, hash)
end


#
##
###
Then /^the xml should be correctly mapped$/ do
  case @direction
  when {:from => :xml, :to => :hash}
    @translation.should == {"doo"=>"d", "foo"=>{"bar"=>{"coo"=>"c"}}, "bar"=>{"boo"=>"b", "foo"=>"a"}}
  when {:from => :hash, :to => :xml}
    @translation.to_s.gsub(/\s/, '').should == '<?xmlversion="1.0"encoding="UTF-8"?><bar><foo>a</foo><boo>b</boo><cuk><coo>c</coo><doo>d</doo></cuk></bar>'    
  when {:from => :hash, :to => :hash}
    @translation.should == {"zoo" => "a", "yoo" => "b", "too" => "c", "soo" => {"roo" => "d"}}
  end
end

Then /^the target should be correctly processed for condition '(.*)'$/ do |condition|
  case condition
  when /unless/
    @translation.should == {"bar" => {"foo" => "a"}}
  when /when/
    @translation.should == {"bar" => {"boo" => "hubbabubba"}}
  end 
end

Then /^the target should be properly concatenated$/ do
  @translation.should == {"event"=>{"new_update_status_code"=>"FOO|BAR|BAZ"}}
#  @translation.should == {"foo"=>{"bar"=>"c|d|e"}}
end

Then /^the customized target should be correctly processed$/ do
  @translation.should == {"event"=>{"new_update_status_code"=>[{"name"=>"Abandoned", "text"=>"bad phone"}, {"name"=>"Rejected", "text"=>"bad word"}]}}
#  @translation.should == {"new_update_status_code"=>[{"name"=>"Abandoned", "text"=>"bad phone"}, {"name"=>"Rejected", "text"=>"bad word"}]}
#  @translation.should == {"boo" => [{"bum" => "baz", "dum" => "coo"}]}
end

Then /^the target should be correctly processed for custom \.to conditions$/ do
#  xml = "<foo><bar>baz</bar></foo>"
  @translation.should == { "value" => { "was" => { "baz" => "baz"}}}
end

Then /^the target should have mappings included from different map$/ do
  @translation.should == {"zoo" => "Dave", "yoo" => "Brady", "too" => "Liz", "soo" => { "roo" => "Brady"}}
end

Then /^the target should have nested mappings included from different map$/ do
  @translation.should == {"contact" => { "first_name" => "Dave", "last_name" => "Brady", "home_phone" => "1231231234"}}
end

