library map;

import 'dart:convert';
import 'dart:html';
import 'dart:js';
import 'dart:math' as math;

class Date {
  int year;
  int month;
  int day;

  Date([this.year = null, this.month = null, this.day = null]);

  static Date parse(String date) {
    List<String> parts = date.split("-");
    int year = int.parse(parts[0]);
    int month = parts.length > 1 ? int.parse(parts[1]) : null;
    int day = parts.length > 2 ? int.parse(parts[2]) : null;

    return new Date(year, month, day);
  }

  String toString() {
    return this.year.toString() + (this.month != null ? '-' + this.month.toString() : '') +
      (this.day != null ? '-' + this.day.toString() : '');
  }

  bool operator==(obj) {
    return obj is Date && this.year == obj.year && this.month == obj.month && this.day == obj.day;
  }

  int get hashCode {
    return this.year * 10000 + (this.month == null ? 0 : this.month * 100) + (this.day == null ? 0 : this.day);
  }
}


class DatePeriod {
  Date start;
  Date end;

  DatePeriod(this.start, [Date end = null]) {
    this.end = end == null ? this.start : end;
  }

  static DatePeriod parse(String date) {
    List<String> dates = date.split("/");
    Date startDate = Date.parse(dates[0]);
    Date endDate;
    if (dates.length == 1) {
      endDate = startDate;
    } else {
      endDate = Date.parse(dates[1]);
    }

    return new DatePeriod(startDate, endDate);
  }

  String toString() {
    return start.toString() + (start == end ? '' : '/' + end.toString());
  }
}


class MapApplication {
  static const String dataPath = "/map";
  static const String landColor = "#ffffdd";

  // Colors for countries
  static final Map<String, String> colors = <String, String>{
      'blue': '#a3cec5',
      'green': '#d3e46f',
      'orange': '#fdc663',
      'pink': '#f3c1d3',
      'purple': '#ceb5cf',
      'red': '#fdaf6b',
      'turquoise': '#aadb78',
      'yellow': '#fae364'
  };

  num width;
  num height;
  JsObject svg;
  JsObject g;
  JsObject map;
  JsObject zoom;
  JsFunction projection;
  JsFunction path;
  Element tooltip;
  Element popover;
  var countries, visited;
  List cities;

  void init() {
    map = context['d3'].callMethod('select', ['.map']);
    width = map.callMethod('property', ['clientWidth']);
    height = width * 0.57;

    zoom = context['d3']['behavior'].callMethod('zoom')
      .callMethod('scaleExtent', [new JsObject.jsify([1, 60])])
      .callMethod('size', [new JsObject.jsify([width, height])])
      .callMethod('on', ["zoom", onZoom]);

    tooltip = new DivElement()
      ..classes.addAll(['country-tooltip', 'hidden']);
    querySelector('.map').append(tooltip);

    popover = querySelector('.popover.info');
    popover.onClick.listen((_) => hidePopOver());

    HttpRequest.request('$dataPath/world.json').then((HttpRequest request) {
      var world = JSON.decode(request.responseText);

      HttpRequest.request('$dataPath/data.json').then((HttpRequest request) {
        var visitedData = JSON.decode(request.responseText);
        initData(world, visitedData);
      }, onError: (_) {
        window.alert("Error loading visited countries data");
        initData(world, {});
      });

    }, onError: (_) => window.alert("Error loading world data."));
  }

  void initData(world, visitedData) {
    visited = visitedData;
    countries = context['topojson']
      .callMethod('feature', [new JsObject.jsify(world), new JsObject.jsify(world['objects']['countries'])])['features'];
    var subunits = context['topojson']
      .callMethod('feature', [new JsObject.jsify(world), new JsObject.jsify(world['objects']['subunits'])])['features'];
    countries.addAll(subunits);
    var regions = context['topojson']
      .callMethod('feature', [new JsObject.jsify(world), new JsObject.jsify(world['objects']['regions'])])['features'];
    countries.addAll(regions);
    cities = [];

    visited.forEach((_, v) {
      if (v['cities'] != null) {
        cities.addAll(v['cities']);
      }
    });
    initPageLayout();
    initBackground();
    initDefaultZoom();
    initCountries();
    initCities();
  }

  void initPageLayout() {
    // Type selector
    var pagination = new Element.div()..classes.add('text-center');
    var list = new Element.ul()..classes.addAll(['pagination', 'pagination-lg']);
    var asMap = new Element.li()..classes.add('active')..append(new Element.span()..appendText("Карта"));
    var asList = new Element.li()..append(new Element.span()..appendText("Список"));
    list..append(asMap)
        ..append(asList);
    pagination.append(list);

    // List panel
    var listPanelBody = new DivElement()
      ..classes.add('panel-body');
    var listPanel = new DivElement()
      ..classes.addAll(['panel', 'panel-default', 'hidden'])
      ..append(listPanelBody);

    var mapContainer = querySelector('.map-container');
    var footer = mapContainer.parent.querySelector('footer');
    mapContainer.parent.insertBefore(listPanel, footer);
    mapContainer.parent.insertBefore(pagination, mapContainer);

    List<Map<String, String>> countries = <Map<String, String>>[];
    visited.forEach((k, v) {
      countries.add({
        'key': k,
        'name': v['name']
      });
    });

    countries.sort((a, b) => a['name'].compareTo(b['name']));

    countries.forEach((e) {
      listPanelBody.append(new HeadingElement.h1()..appendText(e['name']));

      List cities = visited[e['key']]['cities'];
      cities.sort((a, b) => a['name'].compareTo(b['name']));
      Iterable content = cities.map((e) => "<li>${formatCityString(e)}</li>");

      listPanelBody.appendHtml('<ul class="list-unstyled">${content.join('')}</ul>');
    });


    // Swither
    asMap.onClick.listen((_) {
      mapContainer.classes.remove('hidden');
      listPanel.classes.add('hidden');
      asMap.classes.add('active');
      asList.classes.remove('active');
    });

    asList.onClick.listen((_) {
      mapContainer.classes.add('hidden');
      listPanel.classes.remove('hidden');
      asMap.classes.remove('active');
      asList.classes.add('active');
    });
  }

  void initBackground() {
    querySelector('.map>.loading').remove();
    // D3 code
    projection = context['d3']['geo']['polyhedron'].callMethod('waterman')
      .callMethod('scale', [0.121841155 * width])
      .callMethod('translate', [new JsObject.jsify([width / 2, height / 2])])
      .callMethod('rotate', [new JsObject.jsify([20, 0])]);

    JsObject graticule = context['d3']['geo'].callMethod('graticule')
      .callMethod('minorStep', [new JsObject.jsify([5, 5])]);

    path = context['d3']['geo'].callMethod('path')
      .callMethod('projection', [projection])
      .callMethod('pointRadius', [1]);

    svg = map.callMethod('append', ['svg'])
      .callMethod('attr', ['width', width])
      .callMethod('attr', ['height', height])
      .callMethod('call', [zoom]);

    JsObject clipPath = svg.callMethod('append', ['defs'])
      .callMethod('append', ['clipPath'])
      .callMethod('attr', ['id', 'outlineClipPath']);
    clipPath.callMethod('append', ['path'])
      .callMethod('datum', [new JsObject.jsify({"type": "Sphere"})])
      .callMethod('attr', ['class', 'graticule outline'])
      .callMethod('attr', ['d', path]);

    g = svg.callMethod('append', ['g'])
      .callMethod('style', ['clip-path', 'url(#outlineClipPath)']);

    g.callMethod('append', ['path'])
      .callMethod('datum', [new JsObject.jsify({"type": "Sphere"})])
      .callMethod('attr', ['class', 'background'])
      .callMethod('attr', ['d', path])
      .callMethod("on", ["click", (d, i, [_]) => hidePopOver()]);

    g.callMethod('append', ['path'])
      .callMethod('datum', [graticule])
      .callMethod('attr', ['class', 'graticule'])
      .callMethod('attr', ['d', path]);

    g.callMethod("style", ["stroke-width", 1])
      .callMethod('attr', ["transform", "translate(0,0)scale(1)"]);

    g.callMethod("append", ['path'])
      .callMethod("datum", [new JsObject.jsify({'type': "Sphere"})])
      .callMethod("attr", ["class", "graticule outline"])
      .callMethod("attr", ["d", path]);
  }

  void initCountries() {
    // Render countries
    JsObject country = g.callMethod("selectAll", [".country"]).callMethod("data", [countries]);
    country.callMethod("enter")
      .callMethod("insert", ["path", ".graticule.outline"])
      .callMethod("attr", ["class", "country"])
      .callMethod("attr", ["d", path])
      .callMethod("attr", ["id", (d, i, [_]) => d['id']])
      .callMethod("style", ["fill", (d, i, [_]) {
        String regionId;
        String countryId = d['id'];
        if (countryId.length > 3) {
          regionId = countryId;
          countryId = countryId.substring(0, 3);
        }
        var c = visited[countryId];
        if (c == null) {
          return landColor;
        }

        var color = c['color'];
        if (color == null || colors[color] == null) {
          return landColor;
        }

        if (regionId != null) {
          if (visited[countryId]['regions'] != null && visited[countryId]['regions'][regionId] != null) {
            return colors[color];
          }
          return landColor;
        }
        return colors[color];
      }]);

    num offsetLeft = map.callMethod("property", ['offsetLeft']) + 5;
    num offsetTop = map.callMethod("property", ['offsetTop']) - 40;

    country.callMethod("on", ["mousemove", (d, i, [_]) {
      var mouse = context['d3'].callMethod("mouse", [svg.callMethod("node")]);

      var regionId;
      var countryId = d['id'];
      if (countryId.length > 3) {
        regionId = countryId;
        countryId = countryId.substring(0, 3);
      }

      String name = getCountryName(countryId, regionId);
      tooltip
        ..classes.remove("hidden")
        ..style.left = "${mouse[0] + offsetLeft}px"
        ..style.top = "${mouse[1] + offsetTop}px"
        ..innerHtml = name;
    }]);
    country.callMethod("on", ["mouseout", (d, i, [_]) => tooltip.classes.add('hidden')]);
    country.callMethod("on", ["click", (d, i, [_]) {
      var countryId = d['id'];
      if (countryId.length > 3) {
        countryId = countryId.substring(0, 3);
      }

      if (visited[countryId] == null || visited[countryId]['name'] == null) {
        hidePopOver();
        return;
      }
      String name = visited[countryId]['name'];

      var mouse = context['d3'].callMethod("mouse", [svg.callMethod("node")]);

      List cities = visited[countryId]['cities'];
      cities.sort((a, b) => a['name'].compareTo(b['name']));
      Iterable content = cities.map((e) => "<li>${formatCityString(e)}</li>");

      showPopOver(name, '<ul class="list-unstyled">${content.join('')}</ul>', mouse);
    }]);
  }

  String getCountryName(countryId, regionId) {
    String name = "Неизведанная территория";
    if (visited[countryId] != null && visited[countryId]['name'] != null) {
      name = visited[countryId]['name'];
      if (regionId != null) {
        if (visited[countryId]['regions'] != null && visited[countryId]['regions'][regionId] != null) {
          name = visited[countryId]['regions'][regionId] + ' &mdash; ' + name;
        }
      }
    }
    return name;
  }

  void initCities() {
    var city = g.callMethod("selectAll", [".city"]).callMethod("data", [new JsObject.jsify(cities)]);
    city.callMethod("enter")
      .callMethod("insert", ["path"])
      .callMethod("attr", ["class", "city"])
      .callMethod("attr", ["d", (d, i, [_]) => path.apply([new JsObject.jsify({
        "type": "Point",
        "coordinates": [d['lon'], d['lat']]
      })])]);


    num offsetLeft = map.callMethod("property", ['offsetLeft']) + 5;
    num offsetTop = map.callMethod("property", ['offsetTop']) - 40;

    city.callMethod("on", ["mousemove", (d, i, [_]) {
      var mouse = context['d3'].callMethod("mouse", [svg.callMethod("node")]);

      tooltip
        ..classes.remove("hidden")
        ..style.left = "${mouse[0] + offsetLeft}px"
        ..style.top = "${mouse[1] + offsetTop}px"
        ..innerHtml = d['name'];
    }]);
    city.callMethod("on", ["mouseout", (d, i, [_]) => tooltip.classes.add('hidden')]);
    city.callMethod("on", ["click", (d, i, [_]) {
      var mouse = context['d3'].callMethod("mouse", [svg.callMethod("node")]);

      showPopOver(d['name'], "<p>${formatCityString(d, true, true)}</p>", mouse);
    }]);
  }

  void initDefaultZoom() {
    num maxX = -1000000.0;
    num maxY = -1000000.0;
    num minX = 1000000.0;
    num minY = 1000000.0;
    cities.forEach((city) {
      var coords = projection.apply([new JsObject.jsify([city['lon'], city['lat']])]);
      maxX = math.max(maxX, coords[0]);
      minX = math.min(minX, coords[0]);
      maxY = math.max(maxY, coords[1]);
      minY = math.min(minY, coords[1]);
    });

    num scale = 0.95 / math.max((maxX - minX) / width, (maxY - minY) / height);

    List<num> translate = [-(minX + maxX) / 2 * scale + width / 2, -(minY + maxY) / 2 * scale + height / 2];

    zoom.callMethod("scale", [scale]);
    updateZoom(translate, scale);
  }

  num _pointRadius = null;
  num _strokeWidth = null;

  void updateZoom(translate, scale) {
    translate[0] = math.max(math.min(translate[0], 0), width * (1 - scale));
    translate[1] = math.max(math.min(translate[1], 0), height * (1 - scale));

    var scaleInv = (100/scale).round()/100;
    var pointRadius = math.max(0.1, scaleInv);
    if (pointRadius != _pointRadius) {
      _pointRadius = pointRadius;
      path = path.callMethod("pointRadius", [pointRadius]);
      g.callMethod("selectAll", ['.city'])
          .callMethod("attr", ["d", (d, i, [_]) => path.apply([new JsObject.jsify({
        "type": "Point",
        "coordinates": [d['lon'], d['lat']]
      })])]);
    }
    zoom.callMethod("translate", [new JsObject.jsify(translate)]);

    var strokeWidth = math.min(0.2, scaleInv);
    if (strokeWidth != _strokeWidth) {
      _strokeWidth = strokeWidth;
      g.callMethod("style", ["stroke-width", strokeWidth]);
    }
    g.callMethod("attr", ["transform", "translate(${translate.join(',')})scale($scale)"]);
  }

  void onZoom([_a, _b, _c]) {
    JsObject translate = context['d3']['event']['translate'];
    List<num> t = <num>[translate[0], translate[1]];
    num scale = context['d3']['event']['scale'];

    updateZoom(t, scale);


    hidePopOver();
  }

  void showPopOver(String title, String content, mouse) {
    num offsetLeft = map.callMethod("property", ['offsetLeft']) + 5;
    num offsetTop = map.callMethod("property", ['offsetTop']) - 40;

    popover.querySelector('.popover-title').innerHtml = title;
    popover.querySelector('.popover-content').innerHtml = content;

    popover.style.display = 'block';
    int width = popover.clientWidth;
    int height = popover.clientHeight;
    int top = mouse[1] + offsetTop - height + 40;
    popover.classes.toggle('top', top >= 60);
    popover.classes.toggle('bottom', top < 60);
    if (top < 60) {
      top = mouse[1] + offsetTop + 40;
    }
    popover.style
      ..left = "${mouse[0] + offsetLeft - width / 2 - 3}px"
      ..top = "${top}px";
  }

  void hidePopOver() {
    popover.style.display = 'none';
  }

  static final List<String> months = <String>['январь', 'февраль', 'март', 'апрель', 'май', 'июнь', 'июль', 'август',
    'сентябрь', 'октябрь', 'ноябрь', 'декабрь'];
  static final List<String> monthsCase = <String>['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля',
    'августа', 'сентября', 'октября', 'ноября', 'декабря'];

  // TODO cover with tests
  String formatVisitDate(visit, [bool withDay = false]) {
    var result = '';

    String dateString = visit['date'];
    if (dateString != null) {
      DatePeriod period = DatePeriod.parse(dateString);

      if (period.start.year != period.end.year) {
        // Visit starts and ends in different yeas (New Year trip)
        if (period.start.month != null) {
          if (withDay && period.start.day != null) {
            result += period.start.day.toString() + ' ' +
              monthsCase[period.start.month - 1] + ' ';
          } else {
            result += months[period.start.month - 1] + ' ';
          }
        }
        result += "${period.start.year} &ndash; ";
        if (period.end.month != null) {
          if (withDay && period.end.day != null) {
            result += period.end.day.toString() + ' ' +
              monthsCase[period.end.month - 1] + ' ';
          } else {
            result += months[period.end.month - 1] + ' ';
          }
        }
        result += period.end.year.toString();
      } else if (period.start.month != null && period.end.month != null){
        if (period.start.month != period.end.month) {
          // Visit starts and ends in different months
          if (withDay && period.start.day != null) {
            result += period.start.day.toString() + ' ' +
              monthsCase[period.start.month - 1] + ' &ndash; ';
          } else {
            result += months[period.start.month - 1] + ' &ndash; ';
          }
          if (withDay && period.end.day != null) {
            result += period.end.day.toString() + ' ' +
              monthsCase[period.end.month - 1];
          } else {
            result += months[period.end.month - 1];
          }
          result += ' ' + period.start.year.toString();
        } else {
          // Same months
          if (withDay && period.start.day != null && period.end.day != null) {
            result += period.start.day.toString();
            if (period.start.day != period.end.day) {
              result += '&ndash;' + period.end.day.toString();
            }
            result += ' ' + monthsCase[period.start.month - 1];
          } else {
            result += months[period.start.month - 1];
          }
          result += ' ' + period.start.year.toString();
        }
      } else {
        // We know only the year
        result += period.start.year.toString();
      }

      result = '<small>$result</small>';
    }

    return result;

  }

  String formatCityString(city, [bool skipName = false, bool withDay = false]) {
    if (city['visits'] != null && city['visits'][0] != null) {
      String date = formatVisitDate(city['visits'][0], withDay);
      String name = (skipName ? '' : city['name']) + (date != '' ? ' ' + date : '');
      if (city['visits'][0]['link'] != null) {
        name = '<a href="${city['visits'][0]['link']}">$name</a>';
      }
      for (int i = 1; i < city['visits'].length; ++i) {
        var visit = city['visits'][i];
        date = formatVisitDate(visit, withDay);
        if (date != '') {
          if (visit['link'] != null) {
            date = '<a href="${visit['link']}">$date</a>';
          }

          name += ", " + date;
        }
      }

      if (name == '' && skipName) {
        name = '<small>дата неизвестна</small>';
      }
      return name;
    }

    return skipName ? '<small>дата неизвестна</small>' : city['name'];
  }
}
