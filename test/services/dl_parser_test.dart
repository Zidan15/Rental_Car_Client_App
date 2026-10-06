import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_app/services/dl_parser.dart';
import 'package:client_app/services/cloud_ocr_service.dart';

void main() {
  group('SmartDLParser - DL Number Patterns & Normalization', () {
    test('recognizes valid Indian driving license numbers', () {
      expect(SmartDLParser.looksLikeDLNumber('GA0120210001234'), isTrue);
      expect(SmartDLParser.looksLikeDLNumber('GA-01-20210001234'), isTrue);
      expect(SmartDLParser.looksLikeDLNumber('GA 01 20210001234'), isTrue);
      expect(SmartDLParser.looksLikeDLNumber('MH1220180056789'), isTrue);
      expect(SmartDLParser.looksLikeDLNumber('DL0420110012345'), isTrue);
      expect(SmartDLParser.looksLikeDLNumber('KA0520200004321'), isTrue);
    });

    test('rejects invalid or too short DL numbers', () {
      expect(SmartDLParser.looksLikeDLNumber(''), isFalse);
      expect(SmartDLParser.looksLikeDLNumber('GA01'), isFalse);
      expect(SmartDLParser.looksLikeDLNumber('1234567890'), isFalse);
      expect(SmartDLParser.looksLikeDLNumber('NOT_A_DL_NUMBER'), isFalse);
    });

    test('normalizes DL numbers by adding standard state hyphen prefix', () {
      expect(SmartDLParser.normalizeDL('GA0120210001234'), equals('GA-0120210001234'));
      expect(SmartDLParser.normalizeDL('GA-01-20210001234'), equals('GA-01-20210001234'));
      expect(SmartDLParser.normalizeDL('MH 12 20180056789'), equals('MH-1220180056789'));
    });
  });

  group('SmartDLParser - Date Extraction & Classification', () {
    test('extracts dates with various delimiters (slash, hyphen, dot)', () {
      expect(SmartDLParser.extractDateFromText('DOB: 15/08/1998'), equals('15/08/1998'));
      expect(SmartDLParser.extractDateFromText('15-08-1998'), equals('15-08-1998'));
      expect(SmartDLParser.extractDateFromText('Issue: 20.01.2020'), equals('20.01.2020'));
      expect(SmartDLParser.extractDateFromText('No date here'), isNull);
    });

    test('classifies 3 dates into DOB, Issue, and Valid using year logic', () {
      final dates = ['20/05/2018', '15/08/1995', '19/05/2038'];
      final sorted = SmartDLParser.smartSortDates(dates);

      expect(sorted['dob'], equals('15/08/1995'));
      expect(sorted['issue'], equals('20/05/2018'));
      expect(sorted['valid'], equals('19/05/2038'));
    });

    test('classifies 2 dates with large gap as DOB and future Valid date', () {
      final dates = ['10/02/1992', '09/02/2042'];
      final sorted = SmartDLParser.smartSortDates(dates);

      expect(sorted['dob'], equals('10/02/1992'));
      expect(sorted['valid'], equals('09/02/2042'));
    });

    test('classifies 2 dates with small gap as Issue and Valid dates', () {
      final dates = ['15/03/2021', '14/03/2026'];
      final sorted = SmartDLParser.smartSortDates(dates);

      expect(sorted['issue'], equals('15/03/2021'));
      expect(sorted['valid'], equals('14/03/2026'));
    });

    test('classifies single date in distant past as DOB', () {
      final sorted = SmartDLParser.smartSortDates(['15/08/1995']);
      expect(sorted['dob'], equals('15/08/1995'));
    });

    test('handles empty dates list safely', () {
      final sorted = SmartDLParser.smartSortDates([]);
      expect(sorted['dob'], isNull);
      expect(sorted['issue'], isNull);
      expect(sorted['valid'], isNull);
    });
  });

  group('SmartDLParser - Blocklist & Name Filtering', () {
    test('contains government, document, and label keywords in blocklist', () {
      final blocklist = SmartDLParser.notANameBlocklist;
      expect(blocklist.contains('INDIA'), isTrue);
      expect(blocklist.contains('GOVERNMENT'), isTrue);
      expect(blocklist.contains('TRANSPORT'), isTrue);
      expect(blocklist.contains('DRIVING'), isTrue);
      expect(blocklist.contains('LICENCE'), isTrue);
      expect(blocklist.contains('SIGNATURE'), isTrue);
      expect(blocklist.contains('HOLDER'), isTrue);
      expect(blocklist.contains('LMV'), isTrue);
      expect(blocklist.contains('MCWG'), isTrue);
    });

    test('strips blocked words from extracted candidate names', () {
      expect(
        SmartDLParser.applyNameBlocklist('UNION OF INDIA ROHAN SHETTY'),
        equals('ROHAN SHETTY'),
      );
      expect(
        SmartDLParser.applyNameBlocklist('GOVERNMENT OF GOA TRANSPORT ZIDAN SHAIKH'),
        equals('ZIDAN SHAIKH'),
      );
      expect(
        SmartDLParser.applyNameBlocklist('DRIVING LICENCE HOLDER SIGNATURE'),
        isNull,
      );
    });

    test('preserves initials and valid names', () {
      expect(
        SmartDLParser.applyNameBlocklist('ZIDAN Z SHAIKH'),
        equals('ZIDAN Z SHAIKH'),
      );
      expect(SmartDLParser.couldBeName('ZIDAN'), isTrue);
      expect(SmartDLParser.couldBeName('SHAIKH'), isTrue);
      expect(SmartDLParser.couldBeName('GOVERNMENT'), isFalse);
      expect(SmartDLParser.couldBeName('MCWG'), isFalse);
      expect(SmartDLParser.couldBeName('12345'), isFalse);
    });

    test('extracts valid vehicle classes from raw text', () {
      const raw = 'AUTHORISATION TO DRIVE: LMV, MCWG, TRANS';
      final classes = SmartDLParser.extractVehicleClasses(raw);
      expect(classes, containsAll(['LMV', 'MCWG', 'TRANS']));
    });
  });

  group('SmartDLParser - Spatial Field Assignment', () {
    test('assigns fields correctly using spatial coordinates and text elements', () {
      final elements = [
        TextElement(
          text: 'DL: GA0120210001234',
          boundingBox: const Rect.fromLTWH(20, 20, 200, 25),
        ),
        TextElement(
          text: 'NAME:',
          boundingBox: const Rect.fromLTWH(20, 60, 50, 25),
        ),
        TextElement(
          text: 'ZIDAN',
          boundingBox: const Rect.fromLTWH(80, 60, 60, 25),
        ),
        TextElement(
          text: 'SHAIKH',
          boundingBox: const Rect.fromLTWH(150, 60, 70, 25),
        ),
        TextElement(
          text: 'DOB:',
          boundingBox: const Rect.fromLTWH(20, 100, 40, 25),
        ),
        TextElement(
          text: '15/08/1998',
          boundingBox: const Rect.fromLTWH(70, 100, 100, 25),
        ),
        TextElement(
          text: 'VALID:',
          boundingBox: const Rect.fromLTWH(20, 140, 50, 25),
        ),
        TextElement(
          text: '14/08/2038',
          boundingBox: const Rect.fromLTWH(80, 140, 100, 25),
        ),
        TextElement(
          text: 'BG:',
          boundingBox: const Rect.fromLTWH(20, 180, 30, 25),
        ),
        TextElement(
          text: 'O+',
          boundingBox: const Rect.fromLTWH(60, 180, 30, 25),
        ),
      ];

      final result = SmartDLParser.assignFieldsForTesting(
        elements,
        'DL: GA0120210001234\nNAME: ZIDAN SHAIKH\nDOB: 15/08/1998\nVALID: 14/08/2038\nBG: O+\nLMV MCWG',
      );

      expect(result.dlNumber, contains('GA'));
      expect(result.holderName, equals('ZIDAN SHAIKH'));
      expect(result.dateOfBirth, equals('15/08/1998'));
      expect(result.validTill, equals('14/08/2038'));
      expect(result.bloodGroup, equals('O+'));
      expect(result.vehicleClasses, containsAll(['LMV', 'MCWG']));
      expect(result.hasEssentialFields, isTrue);
    });
  });

  group('CloudOCRService - Response Parsing & Cleaning', () {
    late CloudOCRService cloudOcr;

    setUp(() {
      cloudOcr = CloudOCRService();
    });

    test('cleans string artifacts and handles null strings gracefully', () {
      expect(cloudOcr.cleanString('null'), isNull);
      expect(cloudOcr.cleanString('NULL'), isNull);
      expect(cloudOcr.cleanString('   '), isNull);
      expect(cloudOcr.cleanString(null), isNull);
      expect(cloudOcr.cleanString('  GA01 20210001234  '), equals('GA01 20210001234'));
    });

    test('cleans name strings by stripping holder and signature artifacts', () {
      expect(cloudOcr.cleanName('ROHAN SHETTY HOLDER'), equals('ROHAN SHETTY'));
      expect(cloudOcr.cleanName('ROHAN SHETTY HOLDER\'S SIGNATURE'), equals('ROHAN SHETTY'));
      expect(cloudOcr.cleanName('SIGNATURE OF HOLDER'), isNull);
      expect(cloudOcr.cleanName('ZIDAN SHAIKH'), equals('ZIDAN SHAIKH'));
      expect(cloudOcr.cleanName('null'), isNull);
    });

    test('parses clean OpenAI JSON response successfully', () {
      const responseBody = '''
{
  "choices": [
    {
      "message": {
        "content": "{\\"dl_number\\": \\"GA01 20210001234\\", \\"holder_name\\": \\"ROHAN SHETTY\\", \\"father_name\\": \\"RAMESH SHETTY\\", \\"date_of_birth\\": \\"15/08/1998\\", \\"issue_date\\": \\"10/01/2018\\", \\"valid_till\\": \\"14/08/2038\\", \\"blood_group\\": \\"B+\\", \\"address\\": \\"MAPUSA, GOA\\", \\"vehicle_classes\\": \\"MCWG, LMV\\"}"
      }
    }
  ]
}
''';

      final result = cloudOcr.parseResponse(responseBody);
      expect(result, isNotNull);
      expect(result!.dlNumber, equals('GA01 20210001234'));
      expect(result.holderName, equals('ROHAN SHETTY'));
      expect(result.fatherName, equals('RAMESH SHETTY'));
      expect(result.dateOfBirth, equals('15/08/1998'));
      expect(result.issueDate, equals('10/01/2018'));
      expect(result.validTill, equals('14/08/2038'));
      expect(result.bloodGroup, equals('B+'));
      expect(result.address, equals('MAPUSA, GOA'));
      expect(result.vehicleClasses, equals(['MCWG', 'LMV']));
    });

    test('sanitizes reasoning tags <think>...</think> from response', () {
      const responseBody = '''
{
  "choices": [
    {
      "message": {
        "content": "<think>First inspecting the document. The DL number is GA01 20210001234. Name is Rohan Shetty.</think>{\\"dl_number\\": \\"GA01 20210001234\\", \\"holder_name\\": \\"ROHAN SHETTY\\", \\"father_name\\": null, \\"date_of_birth\\": \\"15/08/1998\\", \\"issue_date\\": null, \\"valid_till\\": \\"14/08/2038\\", \\"blood_group\\": \\"O+\\", \\"address\\": null, \\"vehicle_classes\\": \\"LMV\\"}"
      }
    }
  ]
}
''';

      final result = cloudOcr.parseResponse(responseBody);
      expect(result, isNotNull);
      expect(result!.dlNumber, equals('GA01 20210001234'));
      expect(result.holderName, equals('ROHAN SHETTY'));
      expect(result.fatherName, isNull);
      expect(result.bloodGroup, equals('O+'));
      expect(result.vehicleClasses, equals(['LMV']));
    });

    test('strips markdown code fences from JSON output', () {
      const responseBody = '''
{
  "choices": [
    {
      "message": {
        "content": "```json\\n{\\"dl_number\\": \\"MH12 20180056789\\", \\"holder_name\\": \\"ZIDAN SHAIKH HOLDER SIGN\\", \\"date_of_birth\\": \\"10/02/1995\\", \\"vehicle_classes\\": [\\"MCWG\\", \\"LMV\\"]}\\n```"
      }
    }
  ]
}
''';

      final result = cloudOcr.parseResponse(responseBody);
      expect(result, isNotNull);
      expect(result!.dlNumber, equals('MH12 20180056789'));
      expect(result.holderName, equals('ZIDAN SHAIKH'));
      expect(result.vehicleClasses, equals(['MCWG', 'LMV']));
    });

    test('returns null gracefully on empty or malformed API responses', () {
      expect(cloudOcr.parseResponse('{}'), isNull);
      expect(cloudOcr.parseResponse('{"choices": []}'), isNull);
      expect(cloudOcr.parseResponse('invalid json'), isNull);
    });
  });
}
